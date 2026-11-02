# Keyboard shortcuts

[← User guide](../README.md)

Test management has its own shortcuts, in the style of OpenProject's shortcuts (`g w p`,
`n w p`), with `t` as the module letter. Type the keys **one after the other** (within one second),
not together. They work on every page of a project in which Test management is enabled.

| Action | Keys | Notes |
|---|---|---|
| Go to test cases | <kbd>g</kbd> <kbd>t</kbd> <kbd>c</kbd> | |
| Go to test runs | <kbd>g</kbd> <kbd>t</kbd> <kbd>r</kbd> | |
| Go to Test Assistant | <kbd>g</kbd> <kbd>t</kbd> <kbd>a</kbd> | Only when the assistant is switched on and you may use it |
| Go to reports | <kbd>g</kbd> <kbd>t</kbd> <kbd>e</kbd> | |
| New test case | <kbd>n</kbd> <kbd>t</kbd> <kbd>c</kbd> | On the Cases list it jumps into the quick-create title field |
| New test run | <kbd>n</kbd> <kbd>t</kbd> <kbd>r</kbd> | |
| Up one level ("back") | <kbd>u</kbd> | Test management pages that have a parent, see below |
| List of these shortcuts | <kbd>g</kbd> <kbd>t</kbd> <kbd>h</kbd> | Also has your personal switches |

A shortcut is only offered when you have the permission for its target (e.g. *View test runs*,
*Add test cases*, *Manage test runs*). Nothing is bound outside projects.

Shortcuts do nothing while you type in a field, a text area, a select or the editor, while a
dialog is open, or when Ctrl, Cmd, Alt or Shift is held.

## "Back": up one level with <kbd>u</kbd>

| Page | <kbd>u</kbd> opens |
|---|---|
| Test case | the Cases list in the case's folder |
| Edit test case / new test case | the case / the Cases list |
| Cases list in a folder | the parent folder (all cases from a top-level folder) |
| Test run / edit run / new run | the Runs list / the run / the Runs list |
| Milestone / edit milestone | the parent milestone or the Milestones list / the milestone |
| "Run in CI" form | the run, test case or folder it was opened from |

<kbd>u</kbd> goes up in the module's structure, not back in the browser history; the browser's own
back (Alt+← or Cmd+[) still works. **Backspace** and **Ctrl+B** are deliberately not used:
Backspace deletes text, and leaving a form by a stray key press would lose your input; Ctrl+B is
**bold** in the editor and opens the bookmarks sidebar in Firefox.

## Hints and tips

- **Badges**: small key badges (`<kbd>`) on *Create case*, *New run* and the entries of the
  Test management submenu.
- **Tips**: now and then a tip with one random shortcut appears in the bottom corner of a Test
  management page (at most once every 10 minutes per browser, and not on every page). It has
  *All shortcuts* and **Don't show tips again**.
- <kbd>g</kbd> <kbd>t</kbd> <kbd>h</kbd> opens the list of shortcuts, with a link to all OpenProject shortcuts.

OpenProject's own <kbd>?</kbd> opens the general shortcut documentation and does not list the Test
management shortcuts; <kbd>g</kbd> <kbd>t</kbd> <kbd>h</kbd> is the module's list.

## Switching them off

| Who | Where | What |
|---|---|---|
| You | <kbd>g</kbd> <kbd>t</kbd> <kbd>h</kbd> dialog | *Show shortcut tips*, *Show shortcut badges* (saved for your account) |
| You | A tip → *Don't show tips again* | Switches your tips off |
| You | My account → *Disable keyboard shortcuts* (OpenProject setting) | Turns off **all** shortcuts, including the Test management shortcuts, badges and tips |
| Administrator | Administration → Test management → Keyboard shortcuts | *Enable Test management shortcuts* (everyone), *Show shortcut hints and tips* (badges and tips for everyone) |

## For developers

- Mapping and conflict check: `TestManagement::Hotkeys` (`conflicts` is covered by a unit spec).
  It checks the module's sequences against OpenProject's (`? s p m j k`, `g m`, `g o`, `g w p`,
  `g w i`, `g a`, `g c`, `g n`, `g e`, `g p`, `g t`, `n w p`, `d w p`), browser keys (`/`, `'`,
  digits, Backspace) and prefixes within the module. OpenProject's key handler also sees the keys,
  so no sequence contains one of its single keys.
- A layout hook (`view_layouts_base_body_bottom`) renders the configuration, the dialog, the tip and
  one nonced inline script on project pages. One `keydown` listener per window reads the current
  page's configuration, so it works with Turbo Drive. No frontend rebuild.
- Personal choices are stored in the module's table `tm_user_preferences` (OpenProject's user
  preferences are validated against a fixed JSON schema). Only the tip cooldown is kept in
  localStorage.
