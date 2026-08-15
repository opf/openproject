# Frontend

## Directory Structure

- `./src/` - Frontend code
  - `./src/app/` - Legacy Angular modules/components
  - `./src/common/` - Framework-agnostic modules (the `core-common` alias), importable from both Angular and Stimulus. Code belongs here when it depends on neither framework and both sides need it; a helper only Stimulus controllers use belongs in `./src/stimulus/helpers/` instead.
  - `./src/stimulus/` - Stimulus controllers
  - `./src/turbo/` - Turbo integration
- `sortable-lists` batch selection is opt-in: a root enables it with a `selectionEnabled` value, and no other consumer's behavior changes. A root also sets `announcementScope`, so the shared controller's announcements speak the consumer's vocabulary instead of "item", and `selectionDescriptionId`, pointing at one shared element every selected card references via `aria-describedby`. Items declare `mobility` — `fixed`, `confined` or `free` — which gates dragging, selection eligibility, and positional moves alike. A missing value means `free`, so a consumer that renders none keeps working; an unrecognised one falls closed to `fixed` rather than handing the user controls the server will refuse. The pure selection model lives in `./src/common/batch-selection.ts` (framework-agnostic, so Angular consumers can adopt it); the DOM-facing adapter is `sortable-lists/selection.ts`, and gesture interpretation sits behind `sortable-lists/selection-orchestrator.ts`, which takes a narrow host port and imports no Stimulus. Selection identity is `(type, id)`, never the id alone: ids are unique per source table, so a nested list of another type can hold a colliding one. A root must render exactly one instance of each `(type, id)`, and an item declaring no type is refused as a candidate. A batch holds one item type — that cohort rule is orchestrator policy, not a constraint of the model, since identity namespacing and batch compatibility are different concerns. Ranges and select-all (Ctrl/Cmd+A) are both confined to the focused card's list; selecting across lists is a deliberate gap, reserved for a separate mechanism. An item belongs to its nearest ancestor root, so an independently nested root is an ownership boundary. Dragging a selected card moves the whole batch: the root freezes the drag's batch at drag start (`beginDragBatch`), and a selection-enabled root with a `collectionMoveUrl` value submits ordered `ids[]` to the collection move action — for one dragged card or many. Dragging an unselected card still collapses any wider selection onto it. A root's `moveAnnouncementScope` value keys the move announcements the same way `announcementScope` keys the selection ones.
- `data-batch-selected` is written on the sortable item element — the row, in Backlogs — while `aria-current` is written on the card inside it. A stylesheet assuming both live on the same element will silently paint nothing while attribute assertions stay green.

## Configuration Files

- `eslint.config.mjs` - JavaScript/TypeScript linting
- `../package.json` / `./frontend/package.json` - Node.js dependencies

## Version Requirements

- Node: `^24.15.0` (see `package.json` engines)

## Setup

```bash
npm ci && cd ..   # Install Node packages
```

## Code Style

### JavaScript/TypeScript
- **New development**: Use Hotwire (Turbo + Stimulus) with server-rendered HTML
- **Legacy code**: Follow ESLint rules
- Prefer TypeScript over JavaScript
- Use [Primer Design System](https://primer.style/product/) via ViewComponent

## Linting

```bash
# JavaScript/TypeScript
npx eslint src/ && cd ..
```

## Testing

```bash
# Frontend (Jasmine/Karma)
npm test && cd ..
```
