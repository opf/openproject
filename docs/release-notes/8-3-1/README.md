---
  title: OpenProject 8.3.1
  sidebar_navigation:
      title: 8.3.1
  release_version: 8.3.1
  release_date: 2019-03-15
---


# OpenProject 8.3.1

We released
[OpenProject 8.3.1](https://community.openproject.com/versions/1355).  
The release contains several bug and security related fixes and we urge
updating to the newest version.

#### Rails security fixes

#### 

This upgrade include Rails 5.2.2.1 with fixes for [CVE-2019-5418, 
CVE-2019-5419
and CVE-2019-5420](https://weblog.rubyonrails.org/2019/3/13/Rails-4-2-5-1-5-1-6-2-have-been-released/).

#### Bug fixes and changes

  - Fixed: Long Work Package titles not wrapped in
    <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-84">Cost
    Reports</span>
    \[[\#28766](https://community.openproject.com/wp/28766)\]
  - Fixed: Cannot sort by custom field of type “Float” if named
    “Position”
    \[[\#29655](https://community.openproject.com/wp/29655)\]
  - Fixed: WorkPackage search results load results thrice and are slow
    because of it
    \[[\#29715](https://community.openproject.com/wp/29715)\]
  - Fixed: Internal error when accessing budget detail view
    \[[\#29718](https://community.openproject.com/wp/29718)\]
  - Fixed: Search page loads slowly initially
    \[[\#29719](https://community.openproject.com/wp/29719)\]
  - Fixed: Manually set admin flag being unset by SAML authentication
    \[[\#29720](https://community.openproject.com/wp/29720)\]
  - Fixed: Gantt Zoom buttons are inverted
    \[[\#29721](https://community.openproject.com/wp/29721)\]
  - Fixed: Attachments deleted on work package update via email
    \[[\#29722](https://community.openproject.com/wp/29722)\]
  - Changed: Allow instances to define a legal notice link to be
    rendered \[[\#29697](https://community.openproject.com/wp/29697)\]
  - Changed: Make Gravatar default image configurable again
    \[[\#29711](https://community.openproject.com/wp/29711)\]

#### Contributions

A big thanks to community members for reporting bugs and helping us
identifying and providing fixes.

Special thanks for reporting and finding bugs go to Michael Johannessen,
Marc Vollmer, Klaus-Jürgen Weghorn, Ole Odendahl


