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
- `approval_requested`
- `approval_submitted`
- `menu_requested`
- `menu_submitted`
- `sync_snapshot`
- `error`

Routing notes:

- The sender should set `conversation_id` to the target peer reference.
- Cylonix now accepts either:
  - the target peer `StableNodeID`
  - the device FQDN / node name, for example `iphone11.cy123456.cylonix.org`
- Exact matching is done against peer stable ID and device name fields from the current netmap.
