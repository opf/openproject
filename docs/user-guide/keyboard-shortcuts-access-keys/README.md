---
sidebar_navigation:
  title: Keyboard shortcuts and access keys
  priority: 450
description: Keyboard shortcuts and access keys in OpenProject.
keywords: keyboard shortcuts and access keys
---
# Keyboard shortcuts and access keys

OpenProject offers useful keyboard shortcuts to enhance your productivity. We use both access keys and regular shortcuts. When using access keys, press the modifier keys and the access key number. For the regular shortcuts just type the listed keys on any OpenProject page.

> [!TIP]
> You can turn keyboard shortcuts off: open the user menu, navigate to **Account settings** → **Interface** and select **Disable keyboard shortcuts** (see [Disable keyboard shortcuts](../account-settings/interface/#disable-keyboard-shortcuts)). Access keys keep working.

## Shortcuts

| Action | Shortcut | Access key | Inside a project | Outside a project |
| ------ | -------- | ---------- | ---------------- | ----------------- |
| Global search | <kbd>s</kbd> | <kbd>4</kbd> | Focus global search | Focus global search |
| Project search | <kbd>p</kbd> | <kbd>5</kbd> | Open the project select | Open the project select |
| Go to My page | <kbd>g</kbd> <kbd>m</kbd> | – | My page | My page |
| Open shortcuts help | <kbd>?</kbd> | – | Open keyboard shortcuts docs (this page) | Open keyboard shortcuts docs (this page) |
| Open help menu | – | <kbd>6</kbd> | Open the help menu, or the custom help link if your administrator set one | Open the help menu, or the custom help link if your administrator set one |
| Go to Overview | <kbd>g</kbd> <kbd>o</kbd> | – | Project overview | – |
| Go to Work packages | <kbd>g</kbd> <kbd>w</kbd> <kbd>p</kbd> | – | Project work packages | Work packages |
| Go to Wiki | <kbd>g</kbd> <kbd>w</kbd> <kbd>i</kbd> | – | Project wiki start page | Wikis |
| Go to Activity | <kbd>g</kbd> <kbd>a</kbd> | – | Project activity | Activity |
| Go to Calendar | <kbd>g</kbd> <kbd>c</kbd> | – | Project calendars | Calendars |
| Go to News | <kbd>g</kbd> <kbd>n</kbd> | – | Project news | News |
| New work package | <kbd>n</kbd> <kbd>w</kbd> <kbd>p</kbd> | <kbd>2</kbd> | Open the Create menu on work package and Gantt lists, otherwise the new work package form with the first type. The access key works on those lists only | Open the Create menu on work package and Gantt lists, otherwise the new work package form with the first type. The access key works on those lists only |
| Edit | <kbd>g</kbd> <kbd>e</kbd> | <kbd>3</kbd> | Work package subject; Edit button of a wiki page, wiki annotate page or news item; first BIM IFC model | Work package subject; Edit button of a user or placeholder user |
| Open the More menu | <kbd>m</kbd> | <kbd>7</kbd> | Work package list, full view and split view | Work package list, full view and split view |
| Toggle the details view | <kbd>d</kbd> <kbd>w</kbd> <kbd>p</kbd> | <kbd>8</kbd> | Work package list | Work package list |
| Select the next list item (<kbd>j</kbd>) or previous list item (<kbd>k</kbd>) | <kbd>j</kbd> / <kbd>k</kbd> | – | Work package tables | Work package tables |

A shortcut does nothing when its target is not on the page, for example when the module is disabled in the project and its page is missing from the menu.

On narrow screens:

- Open the search with its button before using <kbd>s</kbd> or access key <kbd>4</kbd>.
- Firefox does not react to access key <kbd>3</kbd> on pages whose header has only an Edit action. Use <kbd>g</kbd> <kbd>e</kbd> there.

------

## Modifier keys

### Windows

- Firefox: <kbd>Alt</kbd> + <kbd>Shift</kbd> + access key
- Google Chrome and Microsoft Edge: <kbd>Alt</kbd> + access key

------

### Linux

- Firefox: <kbd>Alt</kbd> + <kbd>Shift</kbd> + access key
- Google Chrome: <kbd>Alt</kbd> + access key

------

### macOS

- Firefox: <kbd>Ctrl</kbd> + <kbd>Opt</kbd> + access key
- Google Chrome: <kbd>Ctrl</kbd> + <kbd>Opt</kbd> + access key
- Safari: <kbd>Ctrl</kbd> + <kbd>Opt</kbd> + access key

------

## Save text in the rich text editor

To quickly save changes in a rich text editor (for example a work package description or a comment) you can use this shortcut.

| Shortcut (Windows / Linux) | Shortcut (Mac) | Action                                                       |
| -------------------------- | -------------- | ------------------------------------------------------------ |
| <kbd>Ctrl</kbd> + <kbd>Enter</kbd> | <kbd>Cmd</kbd> + <kbd>Enter</kbd> | **Save changes.**<br>For inline-editable fields, save the field and close it.<br>For pages with a full WYSIWYG (meetings, wiki pages), submit the form. |

Please also refer to the documentation on [working in the rich text editor in OpenProject](../wysiwyg).

## Clear a work package selection

<kbd>Esc</kbd> clears every work package selection on the page, in tables and card views alike, wherever the focus is. An open menu, dialog or editable field receives the <kbd>Esc</kbd> first, so one keypress never both dismisses something and clears the selection.

| Shortcut (Windows / Linux) | Shortcut (Mac) | Action                                             |
| -------------------------- | -------------- | -------------------------------------------------- |
| <kbd>Esc</kbd> | <kbd>Esc</kbd> | **Clear the selection** in every table and card view on the page. |

## Navigate work package tables

The work package table can be used with the keyboard. It has a single position in the page's tab order: Press <kbd>Tab</kbd> to move into the table, then use the arrow keys to move between cells and rows. Press <kbd>Tab</kbd> again to leave the table and continue to the next part of the page.

| Shortcut (Windows / Linux) | Shortcut (Mac) | Action |
| -------------------------- | -------------- | ------ |
| Arrow keys | Arrow keys | **Move** between cells and rows. |
| <kbd>Home</kbd> / <kbd>End</kbd> | <kbd>Home</kbd> / <kbd>End</kbd> | **Move** to the first or last cell in the row. |
| <kbd>Page Up</kbd> / <kbd>Page Down</kbd> | <kbd>Page Up</kbd> / <kbd>Page Down</kbd> | **Move** up or down one page of rows. |
| <kbd>Ctrl</kbd> + <kbd>Home</kbd> / <kbd>End</kbd> | <kbd>Cmd</kbd> + <kbd>Home</kbd> / <kbd>End</kbd> | **Move** to the first or last cell of the table. |
| <kbd>Shift</kbd> + <kbd>Space</kbd> | <kbd>Shift</kbd> + <kbd>Space</kbd> | **Select or deselect** the focused work package. |
| <kbd>Enter</kbd> | <kbd>Enter</kbd> | **Edit** the cell, follow its only link or button, or move into its controls (<kbd>Tab</kbd> between them, <kbd>Esc</kbd> to
return to the cell). |
| <kbd>F2</kbd> | <kbd>F2</kbd> | **Edit** the cell. |

To change the sort order without drag and drop, use **Move up**, **Move down**, **Move to top** or **Move to bottom** in the context menu (manually sorted tables only).
