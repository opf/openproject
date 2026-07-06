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

**Drop container**:
The whole-list active outline shown while a dragged object hovers a sortable list,
signalling it will land inside. A list-level state — distinct from a per-item **Drop
target** edge — carried by the list's `data-drop-container` attribute.

**Empty drop zone**:
An empty area that can accept a dragged object when there is no existing object to anchor a drop indicator.
_Avoid_: Placeholder

**Row**:
A direct child of a **Rows container**. It may hold a **Sortable item** or be a
non-item marker (e.g. a truncated "show more" row carrying
`data-sortable-lists-prev-item-id`). Distinct from **Sortable item**, which is
the draggable payload — not every row is an item.

**Rows container**:
The element whose direct children are a **Sortable list**'s **Rows**, resolved by
the list controller (`:scope > ul` for Backlogs BorderBox lists; the list element
itself when there is no such child). A structural term for the DOM parent of the
rows — not the interaction-sense "container" that is avoided for drop areas.

**Sortable item**:
An object that can be repositioned by drag and drop within or between sortable lists.
_Avoid_: Draggable item

**Sortable item type**:
A category used to decide whether a sortable item may be dropped into a sortable list.
_Avoid_: Draggable type

**Sortable list**:
An ordered list whose sortable items can be repositioned by drag and drop.
_Avoid_: Container

**Structural row**:
A **Row** identified purely by being a direct child of the **Rows container**,
independent of its tag. Successor to the fixed `<ul>`/`<li>` row shape.

## Relationships

- A **Drag source** remains at the original location while the **Drag preview** follows the pointer.
- A **Drop indicator** marks a candidate location without reserving full object-sized space.
- A **Drop placeholder** reserves object-sized space at a candidate location.
- An **Empty drop zone** may combine the affordances of a **Drop target**, **Drop indicator**, and **Drop placeholder**.
- A **Sortable item** has a **Sortable item type**.
- A **Sortable list** may accept only specific **Sortable item types**.
- An active **Sortable list** shows a **Drop container** outline while a compatible **Sortable item** hovers it, distinct from the per-item **Drop indicator**.
- A **Sortable list** has a **Rows container** whose direct children are its
  **Rows**; a **Row** may hold a **Sortable item**.

## Sortable lists wiring (consumer contract)

The sortable-lists drag-and-drop subsystem is three cooperating Stimulus
controllers. A consumer wires them through values, outlets, targets, and a fixed
DOM shape. This contract is OpenProject-internal (it relies on the app's
`FetchRequest`, toaster, `I18n`, and Primer conventions); it is reusable across
OpenProject features, not as a standalone library.

**Root — `sortable-lists`** (the orchestrator; owns the move request, the drag
monitor, and auto-scroll):
- `accepted-type-value` (optional): the one **Sortable item type** every list
  under this root accepts. Root-scoped — there is one accepted type per root,
  shared by all its lists. Omit to accept any type.
- `move-url-template-value`: a URI template expanded with `{id}` (the moved
  item's id) to build the PUT URL. Without it, no move is persisted.
- `allowed-axis-value` (default `vertical`), `max-scroll-speed-value`
  (default `standard`): auto-scroll tuning.
- Outlets `sortable-lists--list` and `sortable-lists--item`: point at the
  descendant lists and items so the root can hand each its reference.
- Target `scrollable`: each element that should auto-scroll during a drag.

**List — `sortable-lists--list`** (a **Drop target** that shows a **Drop container**
outline while active):
- `type-value` (**required** to be a drop target; a list without it is inert).
- `id-value` (optional): the list id sent as `list_id`.
- `drop-position-value` (default `end`): where a drop that resolves to the list
  itself, rather than to an item edge, inserts — `start` files the item at the top,
  `end` appends it.

**Item — `sortable-lists--item`** (a **Sortable item**; the drag source and edge
indicator owner):
- `id-value` (**required**): the item id; sent as the `{id}` URL segment.
- `type-value` (**required**): the item's **Sortable item type**, matched
  against the root's `accepted-type-value`. There is no default — an item that
  omits id or type appears draggable but silently refuses every drop, so the
  controller `console.warn`s on connect when either is empty.
- Target `handle` (optional): restricts the drag to a handle element.
- Target `preview` (optional): the element cloned for the **Drag preview**.

**DOM shape (required):** a list's **Rows** are the direct children of its
**Rows container** — the element the list controller resolves via its
`rowsContainer` element (`:scope > ul`, falling back to the list element). Rows
may be any tag. A non-item row (e.g. a truncated "show more" marker) may carry
`data-sortable-lists-prev-item-id` so position resolution stays correct in
sparse lists.

**Move wire:** a successful drop PUTs `FormData` (`list_type`, `list_id`,
`prev_id`) to the expanded move URL; the server replies with a turbo-stream. A
422 is treated as a handled validation response (no toast); other failures roll
the row back and toast.

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
- "container" is avoided for drag-and-drop *interaction* language (drop areas) —
  resolved: **Rows container** is a structural DOM term for the rows' parent and
  is exempt from that rule.
