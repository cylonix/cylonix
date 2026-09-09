# Peer Messaging Local WebSocket API

Version: `v1`

Endpoint:

- `ws://127.0.0.1:50321/peer-messaging/v1`

Authentication:

- The client must send an initial JSON frame with `type: "authenticate"`.
- The auth token is shown in the Cylonix peer messaging UI.

Example:

```json
{
  "type": "authenticate",
  "payload": {
    "token": "<peer-messaging-auth-token>"
  }
}
```

After authentication the server sends:

- `authenticated`
- `sync_snapshot`

Supported client actions:

- `send_message`
- `submit_approval`
- `submit_menu_selection`
- `mark_read`

`send_message` example:

```json
{
  "type": "send_message",
  "payload": {
    "conversation_id": "iphone11.cy123456.cylonix.org",
    "conversation_title": "Randy Mac",
    "delivery_policy": "drop",
    "text": "Please approve deployment"
  }
}
```

`delivery_policy` is optional:

- `drop`: fail immediately if the peer cannot be reached
- `queue`: accept the send locally and let the Cylonix API retry it later

Messages sent through this API are stamped with `metadata.origin = "api"`.
The stamp travels with the message to the peer, and both sides use it
(together with the structured `approval_request` / `menu_request` /
`task_summary` kinds) to show an agent badge on the thread's device avatar.

`send_message` can also create a menu-style prompt by including `menu_options`:

```json
{
  "type": "send_message",
  "payload": {
    "conversation_id": "iphone11.cy123456.cylonix.org",
    "conversation_title": "Randy Mac",
    "text": "Choose a follow-up action",
    "menu_options": [
      {
        "id": "open-terminal",
        "title": "Open Terminal",
        "action": "open_terminal"
      },
      {
        "id": "show-status",
        "title": "Show Status",
        "action": "show_status"
      }
    ]
  }
}
```

`submit_approval` example:

```json
{
  "type": "submit_approval",
  "payload": {
    "conversation_id": "device-randy-mac",
    "approval_id": "approval-123",
    "approved": true,
    "note": "Reviewed and approved"
  }
}
```

`submit_menu_selection` example:

```json
{
  "type": "submit_menu_selection",
  "payload": {
    "conversation_id": "iphone11.cy123456.cylonix.org",
    "message_id": "menu-msg-123",
    "action": "open_terminal",
    "title": "Open Terminal"
  }
}
```

Server event types:

- `conversation_upsert`
- `message_received`
- `message_sent`
- `message_delivery_update`
- `messages_read`
- `approval_requested`
- `approval_submitted`
- `menu_requested`
- `menu_submitted`
- `sync_snapshot`
- `error`

Read receipts:

- When the app marks a conversation read (including the `mark_read` command
  above), the daemon sends the peer a small signal outside the message queue:
  "read up to message X". It is never persisted or retried behind messages;
  if the peer is unreachable the newest receipt is parked and retried on a
  backoff timer (15s doubling to 5m, dropped after 24h) and immediately when
  the peer becomes reachable again.
- The peer's daemon turns it into a `messages_read` event. `conversation_id`
  is the reader's peer reference and `payload` carries `from_peer_id`,
  `from_peer_name`, `up_to_message_id`, and `read_at` (RFC 3339).
- On receiving it, the app flips its own messages in that conversation that
  were written no later than `up_to_message_id` from `delivered` (or `sent`)
  to the `read` delivery status and records `read_at` in the message
  metadata. `read` is the highest rung of `delivery_status`; a later
  `message_delivery_update` never downgrades it.
- Peers running a daemon without signal support answer 404; the sender then
  skips receipts to that peer for two hours before trying again, so a peer
  that upgrades is picked up without restarting the sender's daemon.

Routing notes:

- The sender should set `conversation_id` to the target peer reference.
- Cylonix now accepts either:
  - the target peer `StableNodeID`
  - the device FQDN / node name, for example `iphone11.cy123456.cylonix.org`
- Exact matching is done against peer stable ID and device name fields from the current netmap.
