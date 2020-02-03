---
  title: OpenProject 8.3.0
  sidebar_navigation:
      title: 8.3.0
  release_version: 8.3.0
  release_date: 2019-03-07
---


# OpenProject 8.3.0

We released
[OpenProject 8.3.0](https://community.openproject.com/versions/1319).  
The release contains several bug fixes and we recommend updating to the
newest version.

#### Notable changes

 

**Modernized
<span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-57"><span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-57">My
page</span></span> grid implementation**

OpenProject 8.3. introduces a grid-style dashboard that is now being
rolled out to
the *<span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-57"><span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-57">My
page</span></span>*. Additional pages will be converted to this grid in
the future, and additional common widgets will be
created.

![Grit-MyPage](https://1t1rycb9er64f1pgy2iuseow-wpengine.netdna-ssl.com/wp-content/uploads/2019/03/Grit-MyPage-1-1024x522.png)

**Improved search functionality**

The global search functionality of OpenProject has been extended to
auto-suggest work package results and provides improved action buttons
to search globally or in the current project.

![OpenProject
Search](https://1t1rycb9er64f1pgy2iuseow-wpengine.netdna-ssl.com/wp-content/uploads/2019/03/Search-1024x626.png)

**Autocompletion of work package attributes**

List-style attributes of work packages (including custom field lists)
have been modified to provide a filterable
autocompleter.

![Auto-complete](https://1t1rycb9er64f1pgy2iuseow-wpengine.netdna-ssl.com/wp-content/uploads/2019/03/Auto-complete-1024x634.png)

**Improved error reporting for work package bulk editing**

When bulk editing work packages (multiple selected work packages in the
table \> right click and select bulk edit), erroneous work packages were
only reported by their ID. OpenProject 8.3 prints all errors on the bulk
edit page to correct them on the spot.

**Packaged installation uses PostgreSQL**

The packaged installation of OpenProject now suggests to install
PostgreSQL instead of MySQL. For users with previous installations,
nothing will change and their installed MySQL version will be kept. New
users are suggested to use either the autoinstall method of PostgreSQL,
or provide a database connection manually using the database URL. [See
the FAQ for more
information](https://www.openproject.org/download-and-installation/).

**OAuth2 API implementation**

The Openproject APIv3 can now be authenticated using the OAuth2
standard. To register an OAuth applications, visit the new module under
Administration \> OAuth applications.

 

#### Bug fixes and changes

  - Feature: OAuth2 authorization flow
    \[[\#28952](https://community.openproject.com/wp/28952)\]
  - Feature: Global Search: Autocompletion on work package subjects
    \[[\#29218](https://community.openproject.com/wp/29218)\]
  - Feature: Auto completion for work package attributes
    \[[\#29257](https://community.openproject.com/wp/29257)\]
  - Feature: Migrate existing my page data
    \[[\#29357](https://community.openproject.com/wp/29357)\]
  - Feature: Global search defaults on work packages and shows a table
    as result \[[\#29388](https://community.openproject.com/wp/29388)\]
  - Feature: Better error reporting for bulk edit
    \[[\#29561](https://community.openproject.com/wp/29561)\]
  - Feature: Automatic calculation of work packages per pagination based
    on widget height
    \[[\#29467](https://community.openproject.com/wp/29467)\]
  - Changed: Draw work packages without end date up to the current date
    in timeline
    \[[\#25471](https://community.openproject.com/wp/25471)\]
  - Changed: Deactivate option “Use current date as start date for new
    work packages” by default
    \[[\#29468](https://community.openproject.com/wp/29468)\]
  - Changed: When sending iCalendar invitation, include email to user
    who sends out invitation
    \[[\#29485](https://community.openproject.com/wp/29485)\]
  - Changed: Projects are now being deleted in a background job.
  - Fixed: Problems when exporting in unified diff
    \[[\#26599](https://community.openproject.com/wp/26599)\]
  - Fixed: In repository module diff does not escape HTML tags that are
    present in the compared code
    \[[\#26614](https://community.openproject.com/wp/26614)\]
  - Fixed: Incompatible browsers warning not shown in IE11 and older FF
    \[[\#28484](https://community.openproject.com/wp/28484)\]
  - Fixed: Table menu in WYSIWYG editor is cut off on smaller screens
    \[[\#28815](https://community.openproject.com/wp/28815)\]
  - Fixed: Upgrading reverts protocol to HTTP
    \[[\#28954](https://community.openproject.com/wp/28954)\]
  - Fixed: Icon texts are not consistently used in tables
    \[[\#29072](https://community.openproject.com/wp/29072)\]
  - Fixed: Blank circles before work package’s type after upgrading to
    8.1 \[[\#29082](https://community.openproject.com/wp/29082)\]
  - Fixed: Dependencies for fulltext search in work package attachments
    not installed with packager installation
    \[[\#29085](https://community.openproject.com/wp/29085)\]
  - Fixed: Sorting doesn’t work with 8.1 when also using Hierachy
    \[[\#29122](https://community.openproject.com/wp/29122)\]
  - Fixed: Very large custom field is killing web browser
    \[[\#29136](https://community.openproject.com/wp/29136)\]
  - Fixed:
    <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-80"><span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-80">Delete</span></span>
    projects in delayed job
    \[[\#29214](https://community.openproject.com/wp/29214)\]
  - Fixed: SVN fails to get changesets in subfolders which start at a
    revision greater than 1
    \[[\#29402](https://community.openproject.com/wp/29402)\]
  - Fixed: “Set Parent” not translated in work package view
    \[[\#29447](https://community.openproject.com/wp/29447)\]
  - Fixed: WP content does not close right side gap
    \[[\#29448](https://community.openproject.com/wp/29448)\]
  - Fixed: Redundant type declaration in relations tab
    \[[\#29460](https://community.openproject.com/wp/29460)\]
  - Fixed: Better error handling on attachment max size exceeded
    \[[\#29461](https://community.openproject.com/wp/29461)\]
  - Fixed: Improve structure for news section
    \[[\#29464](https://community.openproject.com/wp/29464)\]
  - Fixed: Editor dropdown is cut off when opened to top
    \[[\#29482](https://community.openproject.com/wp/29482)\]
  - Fixed: Custom fields for groups throw error message when set
    \[[\#29486](https://community.openproject.com/wp/29486)\]
  - Fixed: Column shifts when opening autocompleter
    \[[\#29492](https://community.openproject.com/wp/29492)\]
  - Fixed: Gantt chart not properly aligned when using groups
    \[[\#29497](https://community.openproject.com/wp/29497)\]
  - Fixed: White space between first table row and header
    \[[\#29521](https://community.openproject.com/wp/29521)\]
  - Fixed: Different font sizes on WP page
    \[[\#29528](https://community.openproject.com/wp/29528)\]
  - Fixed: Cannot select category because font is invisible
    \[[\#29531](https://community.openproject.com/wp/29531)\]
  - Fixed: Search bar too long on mobile Safari browser
    \[[\#29553](https://community.openproject.com/wp/29553)\]
  - Fixed: Docker incoming-mails not logged
    \[[\#29575](https://community.openproject.com/wp/29575)\]

#### Contributions

A big thanks to community members for reporting bugs and helping us
identifying and providing fixes.

Special thanks for reporting and finding bugs go to Nicolas Salguero,
Andy Shilton, Ricardo Vigatti, Michael Johannessen, Wojtek Chrobok, Timo
Lösch.


