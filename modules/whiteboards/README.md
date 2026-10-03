# OpenProject Whiteboards (prototype)

Collaborative [Excalidraw](https://github.com/excalidraw/excalidraw) whiteboards in projects, synced in real time
through the same Hocuspocus collaboration server and Yjs/CRDT stack as collaborative documents.

## Enabling

1. Configure the collaboration server (Administration → Documents → Collaboration settings), exactly as for documents.
2. Activate the feature flag: `OPENPROJECT_FEATURE_WHITEBOARDS_ACTIVE=true`.
3. Enable the *Whiteboards* project module and grant `view_whiteboards` / `manage_whiteboards`.

## How it fits together

- `Whiteboard` includes `Collaboration::Collaborative`, the concern shared with `Document`. It provides the resource URL
  and read-only decision for the encrypted collaboration token (`Collaboration::OAuth::TokenWithMetadataService`).
- `GET/PATCH /api/v3/whiteboards/:id` follows the contract Hocuspocus relies on
  (`API::V3::Collaboration::CollaborativeContentRepresenter`): `contentBinary` plus an `update` link for writers.
- Hocuspocus picks the `excalidrawWhiteboardAdapter` by resource URL and stores `scene` (live elements in z-order) and
  `searchable_text` next to the Y.Doc binary.
- The browser mounts `<op-whiteboard>` full-screen (`layouts/whiteboards/canvas`) and syncs the scene through
  `ExcalidrawYjsBinding`: one `Y.Map` entry per element, `isDeleted` tombstones, version-gated writes, remote changes
  merged with Excalidraw's `reconcileElements` and kept out of the local undo history. Presence (avatars, cursors,
  selections, follow mode) runs over Hocuspocus awareness.

## Known prototype limitations

- Images are disabled; they should become attachments referenced from the `files` map rather than data URLs in the Y.Doc.
- No journals/activity, no global search registration, no tombstone garbage collection yet.
- Concurrent edits to the *same* element resolve last-writer-wins for the whole element.
