# TODO: Tiered DERP selection for xray vs direct regions

Status: design, to be planned. Interim mitigation already landed (see the last
section). Author context: 2026-09-11, from the iOS NE DERP-flap investigation.

## Problem

The DERP map mixes two fundamentally different kinds of region:

- **Direct regions** — plain DERP over TLS. Fast. Reachable from a free
  network.
- **xray regions** — DERP carried inside an xray VLESS+REALITY+XHTTP tunnel
  (`tailcfg.DERPNode.XRay`, detected by `derphttp.WantsXRayUnderlay`). Always
  slower (double tunnelling plus splithttp framing). Reachable from inside a
  censoring network, where a direct region would be blocked.

netcheck today treats every region the same: it measures a latency for each and
picks the lowest as the home DERP (`Report.PreferredDERP` from
`Report.RegionLatency`). That is wrong for xray in three ways:

1. **STUN cannot measure an xray region.** STUN is a UDP probe to the region's
   STUN port (3478), which sits behind the REALITY decoy, so it never answers.
   Measured on the 16e over 12h: 448+ STUN sends, 0 receives.
2. **The HTTPS fallback is expensive and pointless here.** Because STUN fails,
   netcheck falls back to `measureHTTPSLatency`, which opens a stream over the
   xray tunnel on every ~20s report (the periodic reSTUN cadence, kept active
   forever by the peer-message warm loop). Over 12h that was ~1,100 probes for
   **zero** home-DERP changes. Each burns a slot of the xray mux's finite
   request budget (`HMaxRequestTimes` 600-900), and budget exhaustion forces a
   REALITY re-handshake.
3. **Cross-tier latency comparison is meaningless.** An xray region is a
   different tier, not a faster/slower alternative to a direct region. Ranking
   them together can only produce a wrong choice.

There is also a connectivity gap for mixed pairs. DERP relay is
destination-homed: to reach a peer you dial *that peer's* home region
(`endpoint.go`: `de.derpAddr = peer.HomeDERP()`). So if Alice is censored
(home = xray region) and Bob is free (home = direct region):

- Bob → Alice works: Bob dials Alice's xray home; REALITY fronts fine from a
  free network.
- Alice → Bob fails: Alice must dial Bob's direct home, which is blocked where
  Alice is.

## Design

### Principle: tier before latency

Home selection is two phase. First choose the tier the node lives in, then pick
the lowest-latency region *within that tier*. Never let a cross-tier latency
number decide anything.

### 1. Node DERP policy (a pref)

- `direct` (default, free users): home only on non-xray regions.
- `xray` (censored users): home only on xray regions.
- `auto`: run `direct`; if every direct region fails both STUN and HTTPS over a
  window, fall back to `xray`. Auto-detects censorship with no manual toggle.

Implement with the existing region hook `NoMeasureNoHome` (tailcfg/derpmap.go):
a `direct` node stamps xray regions `NoMeasureNoHome` locally (no probe, no
home); an `xray` node does the reverse. `auto` keeps a slow direct-probe to
notice when censorship lifts. This removes the wasteful probing *by
construction* rather than by throttling.

### 2. Probe only what can change a decision

Within the node's own tier, stop probing on the ~20s reSTUN cadence:

- Tier has one usable region (common for xray): no home choice exists → liveness
  only (the DERP keepalive watchdog already added in magicsock/derp.go), no
  latency probing.
- Tier has several regions: refresh latency every few minutes; the ranking is
  stable.
- Direct-tier nodes keep normal STUN (cheap, works).

### 3. Cross-tier pairs meet at the stricter tier

Rule: when two peers are in different tiers, the relay region for that pair is
the stricter tier both can reach (xray). Needs:

1. Peers advertise their tier as a node capability in the netmap, so a node can
   see "this peer requires xray."
2. For an xray-requiring peer, override destination-homing and relay to that
   peer over the xray region in both directions, keeping an xray connection
   alive while such a peer exists. A free node keeps its fast direct home for
   free peers and descends to xray only for the peers that need it.

Result: free-to-free stays fully direct; censored node lives on xray; a mixed
pair defaults to xray as the common denominator ("Alice's preference wins").

## Work items

- Node DERP-policy pref + `auto` detector (all-direct-unreachable window).
- Per-node `NoMeasureNoHome` stamping by tier at DERP-map ingest.
- Tier capability advertised in the netmap and read on peers.
- Per-peer relay-region override for cross-tier pairs; keep the shared xray
  connection alive (watchdog already covers liveness).
- Remove the interim latency cache below once tier-aware probing exists.

Primitives already present: `DERPNode.XRay`, `WantsXRayUnderlay`,
`NoMeasureNoHome`/`Avoid`/`RegionScore`, destination-homed `de.derpAddr`,
`HomeDERP()`. Most of this is policy on top of existing hooks.

Orthogonal to the flap and keepalive-watchdog fixes; land those first.

## Interim mitigation (landed 2026-09-11)

Until the above is built, `measureHTTPSLatency` caches the last successful xray
HTTPS latency per region for `xrayLatencyCacheTTL` (15m) and serves it instead
of re-dialing on every report (net/netcheck/netcheck.go, `xrayLatencyCache`,
counter `cylonix_xray_latency_cache_hit`). This collapses the ~20s xray probe
cadence to a rare refresh while keeping the region as home and leaving direct
regions and STUN NAT discovery untouched. Liveness is covered by the DERP
keepalive watchdog, not this probe.
