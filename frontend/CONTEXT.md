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
