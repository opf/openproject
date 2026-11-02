# Test cases

[← User guide](README.md)

Test management → **Cases** lists the project's test cases next to the **folder tree**.

## Folders

- Folders form a tree per project (subfolders of any depth). **All cases** shows every case,
  **Unfiled** the cases without a folder. Selecting a folder shows its cases.
- **Deleted** is always the last entry in the tree: soft-deleted cases (recycle bin). Case IDs stay
  reserved and are never reused by new cases.
- **New folder** creates a folder at the top level or inside the selected one (*Add subfolder*).
  Needs **Manage test suites**.
- Layout (Project settings → Test management → *Folder tree layout*): **split pane** in the page
  (default) or **sidebar**, below the Test management submenu on the Cases pages.

## The list

- **Quick create**: type a title in the field above the list and press **Create case** (or
  <kbd>n</kbd> <kbd>t</kbd> <kbd>c</kbd>, which jumps into that field). The case is created in the selected folder.
- **Filters**: search by title, status and priority. Columns: ID, title, labels, priority, status,
  automated, assignee, folder.
- **Export**: CSV, XLS or PDF of the current view.
- **Select cases**: shows checkboxes so you can bulk **Edit**, **Move**, **Copy** or **Delete**
  the selection. Bulk edit only writes fields you change (leave others on *No change*). Copy
  duplicates steps, labels and work-package links and clears the automation reference. Delete
  moves cases to **Deleted**.

## Deleted and restore

- Delete from the case edit (or show) page, or in bulk from the list. Cases move to **Deleted**;
  their numeric ID is kept.
- **Restore** from the Deleted list puts the case back in its previous folder when that folder
  still exists. If the folder was removed, you choose a new folder (or Unfiled).

## A test case

| Field | Notes |
|---|---|
| Title | Required |
| Folder | Optional |
| Status | `ready`, `draft`, `deprecated`, `blocked` |
| Priority | `critical`, `high`, `medium`, `low` |
| Assignee | A project member |
| Preconditions, description | Rich text |
| Steps | Action, test data and expected result per step. Fill in the empty row to add a step. |
| Labels | Comma-separated; new labels are created for the project (colors and renaming in Project settings → Test management → Labels). Labels drive dynamic runs. |
| Linked work packages | The work packages the case covers (search by ID or subject). Needs **Link test cases to work packages**. |
| Automated / automation reference | Links CI results to the case, see below. |

The case page has four tabs:

- **Overview**: the fields above, the linked work packages and who created and last edited it.
- **Runs**: every run that contains the case, with its result.
- **Defects**: linked work packages of type *Bug* or *Defect*.
- **History**: creation and changes (title, status, priority, folder, automation, preconditions and
  description), automated results, and the final result whenever a run containing the case is
  completed or cancelled.

### Automation reference

The reference connects automated results to a case:

| Framework | Reference |
|---|---|
| Playwright | `<file>#<describe> › <title>`, e.g. `tests/login.spec.ts#login › signs in` |
| JUnit | `<classname>#<name>`, e.g. `com.acme.LoginTest#signsIn` |
| Several repositories | `<name>:<reference>` or `<name>/e2e:<reference>`, e.g. `shop:tests/cart.spec.ts#cart › adds an item` |

Instead of a reference, a test can carry the case ID (`@TC-12` tag, `tm_case` annotation or
property). After the first matched upload the case remembers the reported reference. A file-like
reference links to the file on the Git server of its CI connection. Details:
[CI and automation](ci/README.md), sections 1 and 8.

**Steps of automated tests**: an automated test can report its steps; they are linked to the case
steps by a marker such as `[step:2]` in the step title, by position or by title. Keep the step
actions short and distinct so that title matching works. Examples per framework:
[CI and automation → Test steps](ci/README.md#test-steps); results per step:
[Step results and errors](runs.md#step-results-and-errors).

ID tags use the prefix `TC` (`@TC-12`) or the display prefix set in Project settings or
Administration → Test management.

## Work package *Testing* tab

Work packages of projects with Test management get a **Testing** tab (full view and split view,
with a counter). It has a **Milestones | Runs | Cases** switcher with one card per item:

- **Cases**: the linked test cases with their latest result.
- **Runs**: the newest runs (up to 20) that contain a linked case or reference the work package.
- **Milestones**: only when the work package is linked to a milestone (as a reference or through
  its Version). Status, dates, overdue badge, status bar and pass rate. It is the default view
  when present.

Needs **Show Testing tab** and **View test cases**; run results also need **View test runs**.

## Creating cases with the Test Assistant

The [Test Assistant](assistant/README.md) drafts cases from a work package, text, a pull request or
code. Drafts are only saved when you select them, as cases with the status *Draft*.
