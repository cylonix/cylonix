# Cylonix

![Cylonix](./landing.jpeg)

Cylonix is an open source client application for the Cylonix Secure Access Service Edge (SASE) service. On devices, it runs a modified version of Tailscale™ (WireGuard-based mesh VPN) to provide secure, private connectivity.

## Features

- Exit Node as a Service  
  Terminate your WireGuard mesh on a privacy-first infrastructure.  
- Data Privacy  
  End-to-end encryption using WireGuard ensures your traffic remains confidential.  
- Optional Enterprise Security  
  - Cilium-based firewall for fine-grained network policy enforcement  
  - VPP-based policy routing engine for high-performance traffic steering  
- Lightweight by Default  
  Most users need only the WireGuard mesh network; enterprise users can layer on Cilium and VPP for advanced control.

## Architecture

1. WireGuard mesh network termination  
2. (Enterprise only) Cilium firewall integration  
3. (Enterprise only) VPP policy routing engine

The default WireGuard mesh is sufficient for secure peer-to-peer connectivity. Enterprises can enable Cilium and VPP components to enforce security policies and route traffic at scale.

## Getting Started

See [docs/INSTALL.md](docs/INSTALL.md) for build and configuration instructions.

## License

Cylonix is licensed under the BSD 3-Clause License.  
Contributions welcome! See [CONTRIBUTING.md](docs/CONTRIBUTING.md).

## Trademarks

“Tailscale” is a trademark of Tailscale Inc.  
“WireGuard” is a registered trademark of Jason A. Donenfeld.  