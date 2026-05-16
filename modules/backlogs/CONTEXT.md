# Backlogs

Backlogs is the OpenProject context for planning and ordering project work across an inbox backlog, backlog buckets, and sprints.

## Language

**Work package**:
A unit of project work that can be planned, tracked, and moved through Backlogs.
_Avoid_: Item, story

**Work package card**:
The visual representation of a work package in a Backlogs list.
_Avoid_: Item, row

**Backlogs list**:
An ordered Backlogs view location that can contain work packages.
_Avoid_: Container, target

**Position**:
A user-controlled ordinal value that determines where a work package appears within an ordered list.
_Avoid_: Priority order, sort order

**Highlighted gap drop indicator**:
An accent-tinted gap between work package cards that marks the candidate position for a dragged work package.
_Avoid_: Placeholder, drop placeholder

## Relationships

- A **Work package** may appear in a Backlog, a Backlog bucket, or a Sprint.
- A **Work package card** represents one **Work package** in a Backlogs list.
- An **Inbox backlog**, a **Backlog bucket**, and a **Sprint** are Backlogs lists.
- A **Work package** has a **Position** within an ordered list.
- A **Highlighted gap drop indicator** appears at the candidate **Position** for a dragged work package.

## Example Dialogue

> **Dev:** "When a user drags a card from a Backlog bucket into a Sprint, what moved?"
> **Domain expert:** "A **Work package** moved; the card is only how that work package is shown in the Backlogs view."
> **Dev:** "What did it move between?"
> **Domain expert:** "Between **Backlogs lists**."
> **Dev:** "What changes when a Work package is dragged within the same Backlogs list?"
> **Domain expert:** "Its **Position** changes."
> **Dev:** "What is the highlighted gap between two cards during drag?"
> **Domain expert:** "A **Highlighted gap drop indicator**."

## Flagged Ambiguities

- "item" was used to mean **Work package** — resolved: use **Work package** for the domain object.
- "card" was used ambiguously — resolved: use **Work package card** for the visual representation and **Work package** for the domain object.
- "container" was used to mean **Backlogs list** — resolved: use **Backlogs list** for the domain concept and reserve "list" for generic implementation discussions.
- "priority order" conflicts with the separate Work package priority attribute — resolved: use **Position**.
- "placeholder" was used for the highlighted gap — resolved: use **Highlighted gap drop indicator** because it marks a candidate Position without reserving full card-sized space.
