# Sortable lists selection

## Consumer wiring

Batch selection is opt-in per sortable root through `selectionEnabled`. The root
sets `announcementScope` for its translation vocabulary and
`selectionDescriptionId` for one shared description element. Selected items
reference that description through `aria-describedby` on their focus host.

Items declare `mobility`: `fixed`, `confined`, or `free`. Mobility gates dragging,
selection eligibility, and positional moves. A missing value defaults to `free`;
an unrecognised value resolves to `fixed`. Structural rows such as “Show more”
are not sortable items and do not participate in selection.

## Model and ownership

- [BatchSelection](../../../../common/batch-selection.ts) stores membership,
  the anchor, and the baseline preserved while resizing a range. It has no
  framework or DOM dependency.
- [selection.ts](selection.ts) resolves candidates, ranges, live document order,
  and presentation.
- [selection-orchestrator.ts](selection-orchestrator.ts) interprets gestures
  through a narrow host interface and imports no Stimulus.

Selection identity is `(type, id)`. Each root must render exactly one instance
of each pair, and an item without a type is not a selection candidate. The
orchestrator permits one item type per batch; the model itself does not impose
that compatibility policy.

An item belongs to its nearest ancestor sortable root. Independently nested
roots are ownership boundaries. Item lookup, focus targets, and range resolution
must respect the owning item and list.

## Gestures and range sessions

Ctrl/Cmd-click toggles individual items and can build a sparse batch across
lists. The toggled item becomes the anchor even when deselected. Plain click
replaces the selection with the movable item while allowing its activation.

Shift-click, Shift+Space, and Shift+Arrow resize a range within the anchor's
list. Independent selections present when the range starts remain selected,
including selections in other lists. Repeated Shift gestures extend, shrink,
or reverse only the range's contribution. Without an anchor, or when Shift
crosses into another list, selection restarts at the acted-on item. Ranges
crossing unloaded or non-movable items are rejected without changing selection.

Ctrl/Cmd+A replaces the batch with loaded movable items of the focused item's
type in its list. A subsequent Shift gesture can narrow or reverse that
selection. An individual toggle starts a fresh range baseline.

Space toggles the focused item. Arrows move focus between items, including fixed
items; Home/End target the first/last movable item. Focus movement remains
available during a move, but selection mutations are blocked. Escape clears
selection and the anchor at document level, while respecting fields and overlays
that own the key.

Reconciliation prunes unavailable items and rebinds the anchor to its live list.
Losing the anchor or moving it to another list ends the range session; unchanged
reconciliation preserves it.

## Batch movement

Dragging a selected item moves the whole batch. The root freezes the batch at
drag start so changes to selection during the drag do not change the submitted
items. Dragging an unselected item collapses an existing batch onto that item.

A selection-enabled root with `collectionMoveUrl` submits ordered `ids[]` to the
collection move action for one dragged item or many. The root's
`moveAnnouncementScope` sets the translation vocabulary for move announcements,
independently of the selection's `announcementScope`.

## Presentation and feedback

`data-batch-selected` belongs on the sortable item element. In Backlogs this is
the row, while `aria-current` belongs on the card inside it and represents the
work package open in the details pane. Styles must account for those distinct
elements and states. Updating the current work package does not change batch
membership.

Selection gestures announce membership changes, including changes that retain
the same count. Plain navigation clicks announce only when a wider batch
collapses. Rejected ranges and range restarts have distinct translation keys.
Tests use [keyed translation fixtures](testing/selection-translations.ts) to
assert the selected key and plural form without duplicating production copy.
