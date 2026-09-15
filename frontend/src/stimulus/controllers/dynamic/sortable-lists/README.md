# Sortable lists implementation

Consumer wiring, gestures, and movement behavior are documented in Lookbook
under **Patterns → Drag and drop**
(`/lookbook/pages/patterns/drag_and_drop` in a running application):

- [Selection and batch movement](../../../../../../lookbook/docs/20-patterns/44-drag-and-drop[sibling-lists].md.erb)
- [Controller API](../../../../../../lookbook/docs/20-patterns/46-drag-and-drop[api-reference].md.erb)

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

Reconciliation prunes unavailable items and rebinds the anchor to its live list.
Losing the anchor or moving it to another list ends the range session; unchanged
reconciliation preserves it.

The root freezes the drag batch in `freezeDragBatch` during preview generation
and marks its rows in `markDragBatch` at drag start. Both operate on the same
snapshot, independently of later selection changes.

[SortableActionMenu](action-menu.ts) projects action availability and scope onto
Primer menus. The root resolves scope and permission policy; the projection
owns visibility, naming, and focus recovery. Item target connections schedule
one availability refresh after the menu fragment has connected.

Selection feedback tests use [keyed translation fixtures](testing/selection-translations.ts)
to assert the selected key and plural form without duplicating production copy.
