# TODO: peer-messaging history backup & restore (opt-in, encrypted)

**Status**: planned for a future release. Design agreed 2026-09-17; nothing
built yet except the iOS "Save attachment" change described under
"Shipped so far".

**Context**: on 2026-09-17 a developer-tool uninstall (`flutter install`
removes the existing app before installing) wiped the iOS app container on
the 16e, and with it the peer-messaging history, staged attachments and
everything "saved" into the app's own Documents folder. The decision was to
keep the platform convention — deleting the app deletes the history — and
to make survival an explicit user choice instead of moving the store.

## Decision

1. **Delete-app-deletes-history stays the default.** It is what iOS users
   expect, what privacy-first peer messengers do (Signal, WhatsApp), and it
   fits a mesh messenger with no server-side store: a user who deletes the
   app to remove their history must actually get that.
2. **Survival is opt-in and user-controlled**: files the user saves go to a
   location they own; history survives only through a backup the user
   asked for.
3. **No automatic cloud sync of history.** An iCloud-synced store would keep
   history alive silently after a delete and force the user to also clean
   up iCloud.
4. **Do not rely on the keychain or the app group as a bulk store.** The
   group container is deleted with the app; keychain persistence across
   app deletion is long-standing behaviour but not a documented guarantee.

## Where the data lives today

| Platform | Message store | Attachments (managed) | "Save" destination | Survives uninstall |
|---|---|---|---|---|
| iOS | `Library/Application Support/peer_messaging/state.json` | `…/peer_messaging/attachments/<profile>/` and app-group staging | Files export picker (user-chosen) since 2026-09-17; media auto-saved to Photos | store: no; Photos + Files copies: yes |
| macOS direct | `~/Library/Application Support/io.cylonix.sase.direct/peer_messaging/` | same tree | save dialog (defaults under `~/Downloads/Cylonix`) | store: no (bundle removal leaves it, PKG uninstall may not); saved copies: yes |
| macOS NE (sandboxed) | container `Application Support/peer_messaging/` | same | save dialog | store: no; saved copies: yes |
| Android | app data `peer_messaging/` | same | public `Download/` | store: no; Downloads: yes |
| Windows / Linux | app support `peer_messaging/` | same | save dialog | store: usually survives uninstall (not cleaned) |

What survives an iOS uninstall today, and why it matters for restore:

- The tailscale node state and login (keychain-backed): the app came back on
  the same profile id without re-login.
- The daemon's per-profile peer-message inbox (keychain-backed state): on
  relaunch the app replays `message_received` events, so **inbound**
  messages are rebuilt. Outgoing history and attachment bytes are not in
  that inbox.
- Photos auto-saves; files saved through a picker.

## Goals / non-goals

Goals

- User-initiated backup of one profile's conversations, optionally with
  attachment bytes, to a destination the user picks.
- Encrypted at rest with no password the user has to remember.
- Restore after reinstall on the same device and onto a new device.
- Restore merges rather than replaces (a re-login can mint a new profile
  id; restore must not clobber what already exists).

Non-goals

- Server-side storage (the Cylonix control/manage servers never see message
  content).
- Continuous or automatic sync between devices.
- Cross-account import.

## Design

### Archive

One file, e.g. `Cylonix-Messages-<profile-short>-<yyyymmdd-hhmm>.cxbackup`,
an encrypted container around a zip:

```
manifest.json      version, created_at, app version/build, platform,
                   profile {id, login_name, control_url}, counts, checksums
state.json         PeerMessagingState subset for that profile (conversations
                   + messages, attachment metadata with relative paths)
attachments/<conversation-id>/<message-id>/<attachment-id>_<name>   (opt-in)
```

Attachments are optional ("Include attachments (n files, x MB)") because
they dominate size; without them the restored thread shows the message and
a "not on this device" placeholder, the same state as today for a file
that was never downloaded.

### Encryption and key management

- Payload: AES-256-GCM (CryptoKit on Apple; libsodium/`cryptography` on the
  others) with a random 256-bit **backup key** per profile and a random
  nonce per archive. The archive header carries the key id, not the key.
- **Apple**: keep the backup key in the keychain as a generic-password
  item, `kSecAttrSynchronizable = true` so iCloud Keychain carries it to the
  user's other devices, accessibility `AfterFirstUnlock`. The user never
  types anything: iCloud Keychain is itself protected by the device
  passcode through escrow. On the same device the item also survives app
  deletion (observed behaviour, not guaranteed).
- Passcode / Face ID at restore: a keychain access-control flag
  (`userPresence`, `biometryCurrentSet`, `devicePasscode`) makes the OS
  prompt when the key is read, **but such items are device-only and cannot
  sync**. Preferred: keep the synced key and gate the restore in-app with
  Local Authentication (`local_auth`), which gives the same prompt while
  keeping cross-device restore. Secure Enclave keys are not suitable: they
  never leave the device.
- **Recovery key** (fallback for users without iCloud Keychain, or after a
  keychain reset): "Show recovery key" renders the backup key as a 64-digit
  / base32 string and QR; restore accepts it. Same pattern as WhatsApp's
  end-to-end encrypted backups.
- Other platforms: Android → Keystore-wrapped key plus the recovery key
  (Keystore keys are not backed up; Play BlockStore is optional);
  macOS → same keychain item (iCloud Keychain syncs across Mac and iOS);
  Windows → DPAPI; Linux → libsecret. The recovery key is the universal
  fallback everywhere.

### Destination

- iOS / Android: document picker (Files / SAF); the user picks iCloud
  Drive, a local folder or a third-party provider.
- Desktop: save dialog.
- Optional later: the app's own iCloud Drive container (needs the iCloud
  Documents entitlement, which the app does not have today).

### Restore

- Entry points: Settings › Peer Messages › "Restore from backup"; also
  offered once on first launch when the store is empty and a keychain
  backup key exists.
- Merge semantics (same as the profile-recovery migration in
  `PeerMessagingService.migrateConversations`): conversation identity is
  `(id, profile_id)`; move non-colliding conversations, union messages by
  message id for colliding ones, take the max unread count. Attachment
  bytes are placed into the managed store and paths rewritten.
- Profile mapping: if the archive's profile id is not present on the
  device (fresh login minted a new id), offer "import into the current
  profile". Same-account check via login name / control URL in the
  manifest.
- The service owns `state.json` (`_persistState`); run the import through
  the service, not by writing the file.

### UX

Settings › Peer Messages:

- Back up now… (choose destination; toggle "Include attachments")
- Restore from backup…
- Show recovery key
- Footer: "Deleting Cylonix deletes your message history. Back up first if
  you want to keep it."

## Implementation notes

- Flutter: `PeerMessagingService.exportBackup(profileId, {includeAttachments})`
  → bytes/stream; `importBackup(source, key)` → merge. Keep the archive
  writer streaming (videos).
- Keychain access from Flutter: `flutter_secure_storage` supports
  `IOSOptions(synchronizable: true)`; verify the macOS options do the same,
  or add a small method-channel helper next to the existing ones in
  `ios/Runner/AppDelegate.swift`.
- Format versioning from day one (`manifest.version`), and refuse newer
  versions with a clear message.
- Tests: round-trip export/import on a fixture store; merge cases (same
  ids, colliding conversation with disjoint messages, profile remap);
  wrong key; truncated archive.

## Shipped so far

- 2026-09-17: iOS "Save attachment" opens the Files export picker
  (`exportLocalFile` method channel, `UIDocumentPickerViewController`
  `forExporting:asCopy:`) instead of copying into the app's own Documents
  folder. Other platforms already used a save dialog or the public
  Downloads folder.

## Open questions

- Should the daemon inbox be extended to retain outgoing message events
  too, so a reinstall rebuilds both directions without a backup? It lives
  in keychain-backed state on Apple, so size is a concern.
- Retention: keep the last N archives at the destination, or leave that to
  the user?
- Should a backup be offered automatically before the app's own
  "Uninstall" action on macOS?

## References

- Incident: session of 2026-09-17, installd log "Destroying container
  io.cylonix.sase … Data/Application/…" at 23:07:24.
- Profile-scoped storage and the merge rules: memory note
  `reference_peer_messaging_profile_scoping.md`.
- Apple: Keychain Services (`kSecAttrSynchronizable`, `SecAccessControl`),
  CryptoKit `AES.GCM`, `UIDocumentPickerViewController(forExporting:asCopy:)`.
