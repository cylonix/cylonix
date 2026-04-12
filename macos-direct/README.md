# Direct macOS Distribution

This directory contains the `Developer ID` macOS variant of Cylonix.

Key differences from [`/Volumes/2TB-1/src/cylonix/macos`](/Volumes/2TB-1/src/cylonix/macos):

- host app bundle ID: `io.cylonix.sase.direct`
- network extension bundle ID: `io.cylonix.sase.direct.network-extension`
- share extension bundle ID: `io.cylonix.sase.direct.share-extension`
- isolated app group: `group.io.cylonix.sase.direct`
- runtime mode flag: `io.cylonix.distribution_mode = direct`

Packaging flow:

```bash
./scripts/macos_direct/build_direct_distribution.sh archive
./scripts/macos_direct/build_direct_distribution.sh export
./scripts/macos_direct/build_direct_distribution.sh dmg
NOTARY_PROFILE=<keychain-profile> ./scripts/macos_direct/build_direct_distribution.sh notarize
./scripts/macos_direct/build_direct_distribution.sh verify
```

Expected prerequisites:

- `Developer ID Application` signing identities and provisioning assets
- a configured `xcrun notarytool` keychain profile
- Flutter dependencies already resolved for the repo
