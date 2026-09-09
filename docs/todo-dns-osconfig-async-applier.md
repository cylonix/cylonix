# TODO: async OS-config applier for dns.Manager (Android JNI hang, writer side)

**Status**: manager-level redesign deferred to the next major release. An
Android-only mitigation shipped instead (2026-09-07, see "Update" below):
the platform calls now run single-flight on their own goroutine with a
deadline, so a hang bounds the callers' wait and surfaces in health rather
than freezing config changes until app restart.

## Update 2026-09-07: corrected call chains and the Android-only fix

The first bullet under "Problem" is wrong for Android. `VPNFacade.SetDNS`
and the router `Set` only store config. The platform work happens in two
other places, and both were wrapped:

- **Platform DNS read** (`backend.getDNSBaseConfig` → JNI
  `GetPlatformDNSConfig`, a binder read of link properties). Called from
  `dns.Manager.compileConfig` under `m.mu` because the facade reports no
  split-DNS support. Now `platformDNSConfigBounded` (10s deadline, last
  good answer on overrun, cache refreshed when the late call returns,
  warnable `android-dns-read-stuck`).
- **VpnService establish** (`VPNFacade.ReconfigureVPN` → `SetBoth` →
  `settings` → the backend event loop → `updateTUN` → `Builder.establish`).
  Reached from `wgengine.Reconfig` while it holds `wgLock`, which also
  serialises peer lookups; the event loop that ran `updateTUN` was blocked
  too, so state and service events piled up behind the hang. Now
  `updateTUN` runs on a `tunapply.Applier` goroutine: callers wait at most
  20s, a newer config replaces one that has not started, at most one
  establish runs at a time, and a stall raises `android-vpn-apply-stuck`
  until the call returns and the newest config is applied. The `configs`
  reply moved off the loop so the loop stays responsive.

Code: `tailscale-android/libtailscale/tunapply/` (pure Go, host-tested)
and `libtailscale/vpnapply.go`, with marked edits in `backend.go` and
`net.go`. Residual: an establish that eventually returns after the VPN
service was revoked still installs its TUN; the next apply or disconnect
replaces it. The manager-level design below remains the right shape if the
same hang class appears on another platform.

**Owner context**: follow-up to the Android total-DNS-outage fix shipped in
1.0.12+95 (tailscale submodule commits `5197284cd`, `0a9709908`).

## Problem

`dns.Manager` holds `m.mu` across `Set`/`RecompileDNSConfig`, and on Android
those paths make synchronous Go→Java calls while holding it:

- `Set` → `setDNSLocked` → OS configurator → `setCfg` → `b.settings` →
  `updateTUN` → `VpnService.Builder` methods + `Builder.establish()`
  (binder IPC into system_server — can block indefinitely under load /
  MIUI interference).
- `RecompileDNSConfig` → `GetBaseConfig` → `appCtx.GetPlatformDNSConfig()`
  (gomobile JNI callback into Kotlin).

Nothing can rescue a stuck call: Go context cancellation cannot reach
inside a cgo/JNI frame, Android's ANR watchdog ignores background threads,
and tailscale's watchdogEngine only wraps `Engine.Reconfig` (the
link-change → `RecompileDNSConfig` path is outside it).

Field incident 2026-08-22 (Redmi Note 13 5G): one such call wedged during
a Wi-Fi flap burst and held `m.mu` forever. Before +95 that parked every
DNS reply (total silent outage, 40s netd timeouts, 800MB goroutine pile).
After +95 queries are immune (mapper read is atomic; netstack path has a
15s deadline + SERVFAIL), but a recurrence would still silently stop
*config changes* from applying until app restart. Diagnostic fingerprint
of the residual failure: DNS fine, but settings/network changes have no
effect; VPN toggle does not clear it; app restart does.

Not Android-specific in principle: Linux (systemd-resolved/NetworkManager
D-Bus) and Windows (registry/NRPT) configurators can also stall; upstream
carries an OS-config health warnable for a reason.

## Design (agreed 2026-08-22)

Mirror the pattern already used on the Java→Go side of libtailscale
(callbacks post to channels drained by one loop; serialization by code
structure, not by holding locks across foreign calls):

1. `Set` does only the cheap bounded work under `m.mu`: compile the
   config, update `m.config`, compute `(rcfg, ocfg)`. Then it hands the
   compiled OS config to a **single applier goroutine** and returns.
2. Handoff is a **1-slot latest-wins channel**: if an apply is already
   pending, replace it. Flap bursts generate many Sets in seconds; only
   the newest matters, and coalescing prevents a slow platform from
   accumulating a backlog of obsolete binder calls.
3. The applier performs the platform calls (`SetDNS` / `setCfg` /
   `GetBaseConfig` reads it needs) with **no locks held and a deadline**
   (e.g. 30s). On overrun: log loudly, set a dedicated health warnable
   ("OS DNS config apply stuck"), abandon the wait (the goroutine may
   remain parked in JNI — that is acceptable; it no longer owns anything),
   and let the next config change spawn a fresh attempt.
4. Semantic shift to accept: platform-apply errors become asynchronous —
   surfaced via the health tracker instead of `Set`'s return value.
   Upstream already treats most SetDNS failures as health warnings.
5. Consider routing the handoff over the upstream `eventbus` (Manager
   already has an `eventClient`; TrampleDNS rides it) so the diff reads
   native and survives merges. A bespoke channel is fine for v1.

Mark everything `__BEGIN/END_CYLONIX_MOD__`. Files touched:
`tailscale/net/dns/manager.go` (main), possibly
`tailscale-android/libtailscale/net.go` if the applier lives closer to
`setCfg`.

## Testing

- Unit: concurrent Set bursts coalesce (latest config wins, no backlog);
  a blocked fake configurator does not block `Set` returns or queries;
  health warnable sets on deadline and clears on next success.
- Field: install on the Redmi (the AP there flaps naturally, several
  provisioning losses/day per IpClient history); verify config changes
  keep applying across flap bursts and the warnable never fires in
  normal operation. Soak before shipping to other platforms; delete
  stale libwg-go archives before any Apple NE build.

## References

- Root-cause analysis: memory `case_android_dns_manager_deadlock`;
  bootstrap context: memory `reference_cylonix_bootstrap_dns`.
- Upstream provenance: `m.mu` in `Manager.Query` arrived in
  tailscale/tailscale `3b737edbf` (conn25, PR #18548); still present on
  upstream main as of 2026-08-22, no upstream issue filed (deliberately
  deferred).
