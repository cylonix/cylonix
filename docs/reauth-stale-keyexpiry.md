# Bug: reauth rotates node key but netmap returns stale KeyExpiry

**Owner for fix:** cylonix-manager (control plane). The Flutter client and `cylonixd` are working correctly.

**Severity:** UX/correctness. After a successful re-authentication the client keeps warning "Device key expires in N days" forever, so users cannot clear the expiry warning even though the key was renewed.

## Symptom

User clicks **Reauthenticate**, completes the web login. Afterwards:

- Admin web UI shows the node (`randy-cs1-1`, id 51) expiring **in ~5 months** (correct).
- The client app still shows **"Device key expires in 2 days"** and keeps the yellow "Reauthenticate to remain connected" banner.

## Root cause

The control server (cylonix-manager) returns a netmap `MapResponse` in which the **self node has the NEW rotated key but the OLD `KeyExpiry`**. The node DB / admin UI has the correct new expiry; only the netmap node does not reflect it.

The client renders `netmap.SelfNode.KeyExpiry` verbatim, so it is faithfully showing the stale value the server sent.

## Evidence (diagnosed 2026-06-28)

Node: id 51, `randy-cs1-1.local.cylonix.io`, tester@cylonix.io, tailnet `vital-skylark.cylonix.org`, control `manage.cylonix.io`.

1. **Key rotation succeeded** — `cylonixd` logs during reauth:
   ```
   netmap diff:
   -netmap: self: [LMFx0] auth=machine-authorized u=tester@cylonix.io
   +netmap: self: [SiT9D] auth=machine-authorized u=tester@cylonix.io
   magicsock: SetPrivateKey called (changed)
   wg: UAPI: Updating private key
   ```

2. **Netmap carries the new key but stale expiry** — `cylonix debug netmap`:
   ```
   SelfNode.ID       : 51
   SelfNode.Name     : randy-cs1-1.local.cylonix.io.
   SelfNode.Key      : nodekey:4a24fd0c14a9de2b...   (NEW, rotated)
   SelfNode.KeyExpiry: 2026-06-30T09:59:20.674075Z   (OLD)
   ```
   The expiry is **identical to the microsecond** to the pre-reauth value — a literal stale value, not recomputed.

3. **Server never sent the new expiry** — no Nov/Dec-2026 (5-month) timestamp appears anywhere in `cylonixd` logs after the reauth.

4. **Not a client merge/display bug** — other peers in the same netmap carry varied future expiries (e.g. `2026-11-13`, `2026-09-10`), so the client applies per-node `KeyExpiry` faithfully; it does not single out the self node.

## Requested fix (cylonix-manager)

When an interactive re-authentication rotates a node's key, ensure the **self node's `KeyExpiry` in the generated `MapResponse` / netmap reflects the updated expiry** (the value already stored in the node DB and shown in the admin UI). Currently the register/reauth path updates the node key and the DB expiry but the netmap generation emits the previous `KeyExpiry`.

Likely areas:
- Register/reauth handler that rotates the key — confirm it also updates the node's expiry used by netmap generation, not just the DB record the admin UI reads.
- Netmap/`MapResponse` builder for the self node — ensure it reads the current expiry rather than a cached/previous value.

## Acceptance check

After reauth, on the client run:
```
cylonix --socket=/run/cylonix/cylonixd.sock debug netmap | grep KeyExpiry
```
`SelfNode.KeyExpiry` should match the admin UI (~5 months out), and the client's "key expiring" banner should clear without any reconnect/toggle.

## Out of scope (already correct / done on client)

- `cylonixd` key rotation and WireGuard reconfig.
- Flutter reauth UX: drops to the login page and auto-launches the login URL like a normal login (`reauthenticate()` + `reauthInProgressProvider` in `lib/viewmodels/ipn_state_notifier.dart`, routing in `lib/main_view.dart`).
