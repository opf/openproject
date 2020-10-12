---
  title: OpenProject 4.0.5
  sidebar_navigation:
      title: 4.0.5
  release_version: 4.0.5
  release_date: 2015-01-07
---


# OpenProject 4.0.5

OpenProject 4.0.5 has been released which contains several bug fixes.  
We advise everyone to update their OpenProject installations.

The following bugs have been fixed in the core:

  - When sorting by a version in the work package list, the result was
    not shown but an unclear error message displayed
    ([\#17928](https://community.openproject.org/work_packages/17928 "Sorting by version leads to 500 in experimental API (\"Unable to retrieve query from URL\") (closed)")).
  - Clicking on the project name in a timeline let to “Page not found”
    ([\#17819](https://community.openproject.org/work_packages/17819 "[Regression] Page not found when clicking on project link in timeline (NaN in link) (closed)")).
  - The “Close” icon of modals was cut off
    ([\#17818](https://community.openproject.org/work_packages/17818 "[Regression] Close icon of modals is cut off (closed)")).
  - Dates in the work package list were sometimes not displayed properly
    ([\#17043](https://community.openproject.org/work_packages/17043 "Single bad translation on work package table. (closed)")).
    Thanks a lot to [Mike
    Lewis](https://community.openproject.org/users/35400) for reporting
    this error\!

Additionally, the work package export via CSV is working properly again
([\#16813](https://community.openproject.org/work_packages/16813 "CSV Export is fixed (closed)")).
Before, only the default columns were displayed in the exported file.  
A big thanks goes to [Thomas Tribolet](https://github.com/TribesTom) for
fixing this bug\!

Finally, syntax highlighting is working again (e.g. in the wiki and
repository):

![SyntaxHighlighting](http://1t1rycb9er64f1pgy2iuseow-wpengine.netdna-ssl.com/wp-content/uploads/2015/01/SyntaxHighlighting.png)

In the Translations plugin an error was fixed which caused translations
in the work package list not to be displayed properly
([\#17944](https://community.openproject.org/work_packages/17944 "Missing js files added (closed)")).  
For a complete list of changes, please refer to the [Changelog
v4.0.5](https://community.openproject.org/versions/566) or take a look
at [GitHub](https://github.com/opf/openproject/tree/v4.0.5).


