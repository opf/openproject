# Frontend

The OpenProject frontend context describes user interface interaction language shared across frontend features.

## Language

**Drag preview**:
The temporary visual representation that follows the pointer during a drag.
_Avoid_: Mirror

**Drag source**:
The original draggable element while it is being dragged.
_Avoid_: Placeholder

**Drop indicator**:
A visual marker that shows where a dragged object will be placed.
_Avoid_: Placeholder

**Drop placeholder**:
A reserved space that approximates the size of the dragged object at a candidate drop location.
_Avoid_: Drop indicator

**Drop target**:
An area that can accept or reject a dragged object.
_Avoid_: Container

**Empty drop zone**:
An empty area that can accept a dragged object when there is no existing object to anchor a drop indicator.
_Avoid_: Placeholder

**Sortable item**:
An object that can be repositioned by drag and drop within or between sortable lists.
_Avoid_: Draggable item

**Sortable item type**:
A category used to decide whether a sortable item may be dropped into a sortable list.
_Avoid_: Draggable type

**Sortable list**:
An ordered list whose sortable items can be repositioned by drag and drop.
_Avoid_: Container

## Relationships

- A **Drag source** remains at the original location while the **Drag preview** follows the pointer.
- A **Drop indicator** marks a candidate location without reserving full object-sized space.
- A **Drop placeholder** reserves object-sized space at a candidate location.
- An **Empty drop zone** may combine the affordances of a **Drop target**, **Drop indicator**, and **Drop placeholder**.
- A **Sortable item** has a **Sortable item type**.
- A **Sortable list** may accept only specific **Sortable item types**.

## Sortable lists wiring (consumer contract)

The sortable-lists drag-and-drop subsystem is three cooperating Stimulus
controllers. A consumer wires them through values, outlets, targets, and a fixed
DOM shape. This contract is OpenProject-internal (it relies on the app's
`FetchRequest`, toaster, `I18n`, and Primer conventions); it is reusable across
OpenProject features, not as a standalone library.

**Root — `sortable-lists`** (the orchestrator; owns the move request, the drag
monitor, and auto-scroll):
- `accepted-type-value` (optional): a root-scoped fallback **Sortable item
  type** accepted by any list under this root that does not declare its own
  `accepted-types-value`. Single consumers (e.g. Backlogs) can set just this;
  omit to accept any type. Prefer per-list `accepted-types-value` for
  multi-type roots.
- `move-url-template-value`: a URI template expanded with `{id}` (the moved
  item's id) to build the PUT URL. Without it (and without
  `move-url-templates-value`), no move is persisted.
- `move-url-templates-value` (optional): a JSON object mapping **Sortable item
  type** → URI template, for roots that move more than one type to different
  endpoints. The dragged item's type selects the template (expanded with
  `{id}`); falls back to `move-url-template-value` when the map has no entry.
- `position-mode-value` (default `relative`): the move wire format.
  `relative` posts `prev_id`; `absolute` posts `position` (1-indexed) +
  `target_id` (see Move wire). Use `absolute` for backends that expect an
  absolute insert position rather than a relative anchor.
- `allowed-axis-value` (default `vertical`), `max-scroll-speed-value`
  (default `standard`): auto-scroll tuning.
- Outlets `sortable-lists--list` and `sortable-lists--item`: point at the
  descendant lists and items so the root can hand each its reference.
- Target `scrollable`: each element that should auto-scroll during a drag.

**List — `sortable-lists--list`** (a **Drop target**):
- `type-value` (**required** to be a drop target; a list without it is inert).
  Sent to the server as `list_type`; it is a server-facing label, not the
  accept rule.
- `id-value` (optional): the list id sent as `list_id` (relative mode) or
  `target_id` (absolute mode).
- `accepted-types-value` (optional): a JSON array of the **Sortable item
  type**s this list accepts. When set, only these types may drop here; when
  unset, the list falls back to the root's `accepted-type-value` (or accepts
  any type if that is also unset).

**Item — `sortable-lists--item`** (a **Sortable item**; the drag source and edge
indicator owner):
- `id-value` (**required**): the item id; sent as the `{id}` URL segment.
- `type-value` (**required**): the item's **Sortable item type**, matched
  against the target list's `accepted-types-value` (or the root's
  `accepted-type-value` fallback), and against an item edge's own `type-value`.
  There is no default — an item that omits id or type appears draggable but
  silently refuses every drop, so the controller `console.warn`s on connect
  when either is empty.
- Target `handle` (optional): restricts the drag to a handle element.
- Target `preview` (optional): the element cloned for the **Drag preview**.

**DOM shape (required):** rows are `<li>` elements, sitting either directly under
the list element or inside a single nested `<ul>`. A non-item row (e.g. a
truncated "show more" marker) may carry `data-sortable-lists-prev-item-id` so
position resolution stays correct in sparse lists.

**Move wire:** a successful drop PUTs `FormData` to the expanded move URL; the
server replies with a turbo-stream. The body depends on `position-mode-value`:
- `relative` (default): `list_type`, `list_id`, `prev_id` (the id of the item
  the moved row now follows; empty = top of list).
- `absolute`: `list_type`, `target_id` (the destination list's `id-value`,
  omitted when null), `position` (1-indexed slot among the destination list's
  item rows, computed after the optimistic reorder). No `prev_id`.

A 422 is treated as a handled validation response (no toast); other failures
roll the row back and toast.

## Example Dialogue

> **Dev:** "What should we call the floating visual during a drag?"
> **Domain expert:** "The **Drag preview**."
> **Dev:** "Is an 8px highlighted gap a placeholder?"
> **Domain expert:** "No — it is a **Drop indicator** because it marks a candidate location without reserving full object-sized space."

## Flagged Ambiguities

- "mirror" is Dragula-specific — resolved: use **Drag preview**.
- "placeholder" was used for highlighted gaps — resolved: use **Drop indicator** unless full object-sized space is reserved.
- "container" was used for drop areas — resolved: use **Drop target** for drag-and-drop interaction language.
- "draggable type" was inherited from the generic drag-and-drop controller — resolved: use **Sortable item type**.
