---
  title: OpenProject 4.2.0
  sidebar_navigation:
      title: 4.2.0
  release_version: 4.2.0
  release_date: 2015-07-07
---


# **OpenProject 4.2.0**

## **Language support for OpenProject plugins**

OpenProject 4.2.0 includes language support for OpenProject core and
plugins
([\#14922](https://community.openproject.org/work_packages/14922)) and
creates the foundation for a complete translation of OpenProject.

In total, more than 30 languages exist for OpenProject for which
translations can be added or changed via CrowdIn.

To help translate OpenProject in additional languages take a look at the
[OpenProject projects on CrowdIn](https://crowdin.com/projects/opf).

To request additional languages, please contact the project managers via
CrowdIn.

Users of the manual installation should remove the translations plugin
from their Gemfile.plugins since Translations are now provided by the
core (Gemfile).



## **Improved navigation**

A couple of changes have been made to the OpenProject navigation
([\#20530](https://community.openproject.org/work_packages/20530)).

Navigation entries which previously were quite hidden (such as viewing
all work packages, viewing news and time entries) on the “View all
projects” page have been added to the “Modules” drop down menu for
easier and more intuitive access
([\#20269](https://community.openproject.org/work_packages/20269)).

The administration can now be accessed via the drop down below the user
name.

Cost types have been moved from the Modules drop down to the
administration navigation
([\#20503](https://community.openproject.org/work_packages/20503)).

The option “Spent time” has been renamed “Time sheet”
([\#20219](https://community.openproject.org/work_packages/20219)).



## **Improved design**

OpenProject 4.2 contains various design improvements to provide a better
and cleaner user interface.

For instance, the search and help icon (which now opens in a new window
([\#20627](https://community.openproject.org/work_packages/20627)) in
the header have been reduced in size
([\#20540](https://community.openproject.org/work_packages/20540)).

Changes include adjustments in font size
([\#19099](https://community.openproject.org/work_packages/19099),
[\#19911](https://community.openproject.org/work_packages/19911)),
alignment adjustments
([\#19559](https://community.openproject.org/work_packages/19559),
[\#20471](https://community.openproject.org/work_packages/20471)) and
standardized use of UI elements.

## **Usability improvements**

A number of usability improvements have been included with OpenProject
4.2.

For example, users email addresses are no longer displayed in the user
profile by default after inviting or registration a new user account
([\#20574](https://community.openproject.org/work_packages/20574)).

Additionally, the option to create new sub projects has been moved from
the project overview to the project settings
([\#19972](https://community.openproject.org/work_packages/19972)).

## **Additional functionalities for API v3**

Several new features have been included in the future OpenProject API.
The [API v3](https://www.openproject.org/development/api/) now enables
work package creation
([\#19987](https://community.openproject.org/work_packages/19987)), CRUD
operations for work package attachments
([\#19988](https://community.openproject.org/work_packages/19988)) and
includes basic auth
([\#19294](https://community.openproject.org/work_packages/19294)).

Please note that the API v3 is still a draft.

## **Substantial number of bug fixes**

A large number of bugs have been fixed with the release of OpenProject
4.2.
