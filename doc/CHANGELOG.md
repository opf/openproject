<!---- copyright
OpenProject is a project management system.
Copyright (C) 2012-2014 the OpenProject Foundation (OPF)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License version 3.

OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
Copyright (C) 2006-2013 Jean-Philippe Lang
Copyright (C) 2010-2013 the ChiliProject Team

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

See doc/COPYRIGHT.rdoc for more details.

++-->

# Changelog

* `#1030` Fix: New target version cannot be created from work package view

## 3.0.8

* new version scheme
* `#4752` Fix button contrast
* `#4019` Fix focus on project creation
* `#4021` Separate focus for main menu expander
* `#4258` Text alignment consistency in tables
* `#6288` Editing relations in modal dialog leads to warning
* `#7236` Filtering for asignee role returns wrong result
* `#7898` Watchers are not sorted alphabetically in work package screen
* `#9931` APIv2 does not rewire parents correctly
* `#10232` Work package filter introduced by plugins not displayed

## 3.0.4

* `#8421` Make subdirectory configuration less of a hassle
* `#5652` Fixes: Custom fields with empty name can be created
* `#7812` 404 when opening keyboard shortcuts in a OpenProject instance running in subfolder
* `#7893` Notification message support for Internet explorer 9 missing
* `#7682` Status of work package not displayed when linking work package via ## or ###
* `#4031` Expand folder icon missing in front of repository folders
* `#7234` Highlighting of differences in repository does not work
* `#7493` Work packages with only start date or end date not displayed properly
* `#7623` Replace remaining icons by icon font
* `#7499` No default work package status possible
* `#7492` Timeline outside of scroll area is broken in IE 11
* `#7384` Headlines in wiki table of content are broken
* Fix input parsing of respoman
* Fix: Icon color in themes
* Fix: Fixed typo which causes wiki pages to fail to load

## 3.0.3

* Update Rails to 3.2.18 to fix CVE-2014-0130

## 3.0.2

* `#1725` Content-sniffing-based XSS for attachments
* `#6310` API v1 is now deprecated and will be removed in the next major release of OpenProject
* `#7056` Enable Active Record Session Store
* `#7177` Fix: Journal not created in connection with deleted note
* `#7295` Fix: Regression in Ruby 2.1.1

## 3.0.1

* `#5265` Fix: Error adding Work Package
* `#5322` Fix: First Journal Entry of chiliproject issues shows incorrect diff

## 3.0.0

## 3.0.0pre51

* `#3701` Fix: Filter custom fields of work packages in timeline reports
* `#5033` Migration RepairInvalidDefaultWorkPackageCustomValues fails on Postgres

## 3.0.0pre50

* `#4008` Deactivating work package priorities has no effect
* Removed path from guessed host

## 3.0.0pre49

* `#2616` Fix:  Search: Clicking on 'Back' results in wrong data
* `#3084` Fix: [Administration - Work Packages] Workflow Status sorting not respected
* `#3312` Fix: [Administration - Custom Fields] "Visible" and "Editable" in user custom field cannot be unchecked
* `#4003` Fix: Revisions in Activity overview are assigned to wrong person
* `#4008` Fix: Deactivating work package priorities has no effect
* `#4046` Update copyright Information to include 2014
* `#4115` [Subdirectory] Broken Redirects
* `#4285` Copy Workflow mixes workflow scopes
* `#4296` Adapt new workpackage form layout
* `#4793` Fix: [Search] Current project scope not shown
* `#4797` Fix: [Subdirectory] Broken Links
* `#4858` XSS in wp auto-completion
* `#4887` Second grouping criterion seems to have an and conjunction
* Added pry-byebug for ruby 2.1

## 3.0.0pre48

* `#1390` Fix: Deleting Issue Categories from a project - route not defined
* `#2701` Fix: [Groups] Error message not displayed correctly.
* `#3217` Fix: [Project settings] Page not found when adding/deleting members and clicking pagination
* `#3725` Fix: Trying to delete a Project without checking "Yes" results in Error
* `#3798` Fix: Typo leading to internal server error
* `#4105` Fix: Remove links from fieldset
* `#4123` Fix: [Accessibility] Link comprehensibility
* `#4715` Fix: Wrong escaping in destroy info
* `#4186` Long work package subject covers up edit buttons
* `#4245` When adding a block to MyPage the other blocks are gone
* `#4337` Fix: HTTP 500 when creating WP with note via API
* `#4654` Activity: Wrong id of work package when time spent
* `#4722` Wrong weekday in date picker
* `#4755` Wrong message "project identifier can't be edited"
* `#4761` Internal error when creating or editing timeline in accessibility mode
* `#4762` List of watchers displayed twice when creating a work package

## 3.0.0pre47

* `#3113` [API] Read access on work package workflows for API v2
* `#3903` Fix: [Search] Project scope lost when clicking on search category link
* `#4087` Fix: [Accessibility] No error messages for blind users
* `#4169` Fix: CSV Export can't handle UTF-8 in conjunction with ASCII letters >= 160 (such as ä)
* `#4266` Custom fields not used as filters are displayed in timeline configuration
* `#4331` Wrong error message for custom fields in query

## 3.0.0pre46

* `#3335` Fix: Mass assignment in members controller
* `#3371` [Work Package Tracking] Wrong 404 when custom query not exists
* `#3440` New workpackage form layout
* `#3947` [CodeClimate] Mass Assignment BoardsController
* `#4087` Accessible form errors
* `#4098` Keyboard operation: links accessible with Screenreadern
* `#4090` [FIX] Tab order of my project page
* `#4103` [Accessibility] Add missing field sets
* `#4105` Remove links from fieldset
* `#4109` Missing hidden tab selection label
* `#4110` Position: Status/Funktion von Links ist nicht klar
* `#4112` Usage of layout tables in work packages index
* `#4118` Fix: Add missing labels
* `#4123` Icon link table comprehensibility
* `#4162` Missing html_safe on required list custom fields with non empty default value
* Allow configuring memcache via configuration.yml or environment variables

## 3.0.0pre45

* `#3113` [API] Read access on work package workflows for API v2
* `#3114` [API] Provide custom fields in work-package index
* `#3116` [API] Distinguishable Status-Codes for wrong credentials and missing API
* `#3347` [API] Make priorities available via API
* `#3701` Filter custom fields of work packages in timeline reports
* `#3732` Summary for work package responsibility
* `#3733` Responsible widget for my pag
* `#3884` [Timelines] Show custom fields of work packages in timeline reports
* `#3980` In Email settings "Issue" is used
* `#4023` [Accessibility] Fixes tabbing inside modals
* `#4024` [Accessibility] Add proper page titles for sub pages
* `#4090` 'Session Expires' setting breaks API
* `#4100` use icon from icon font for toggle multiselect in filter section
* `#4101` Headings: Fix typos in german translation
* `#4102` [Accessibility] Fixes screen reader compatibility for 'further analyze' links in work package summary
* `#4108` Fixes German translation of months
* `#4163` Extend authorization-API to return current user id
* Improves JavaScript tests.
* News subject contained in URL
* Removes mocha mocking framework.
* Update pg-gem version

## 3.0.0pre44

* `#2018` Cleanup journal tables
* `#2244` Fix: [Accessibility] correctly label document language - custom fields
* `#2520` Creating projects is possible with no types selected
* `#2594` Fix: [Activity] Too many filter selects than necessary
* `#3215` Datepicker - Timelines calendar weeks out of sync
* `#3249` [Work Package Tracking] Work packages of type none are displayed as if they were of type work packages
* `#3332` [CodeClimate] Mass Assignment AuthSourcesController
* `#3333` [CodeClimate] Mass Assignment RolesController
* `#3347` [API] Make priorities available via API
* `#3438` Activity default value makes log time required
* `#3451` API references hidden users
* `#3481` Fix: [Activity] Not possible to unselect all filters
* `#3653` Entries in field "Responsible" are not ordered alphabetically
* `#3730` Setting responsible via bulk edit
* `#3731` Setting responsible via context menu
* `#3774` Fix: [API] Not possible to set journal notes via API
* `#3808` Assignee cannot be set to "none" via bulk edit
* `#3843` Prettier translations for member errors
* `#3844` Fixed Work Package status translation
* `#3854` Move function and Query filters allows to select groups as responsible
* `#3865` Detailed filters on dates
* `#3974` [Timelines] Typo at creating timelines
* `#4023` [Accessibility] Keep keyboard focus within modal while it's open
* Add Gruntfile for easier JavaScript testing.

## 3.0.0pre43

* `#2153` [Accessibility] Required fields MUST be displayed as required - group new
* `#2157` [Accessibility] Required fields MUST be displayed as required - enumeration new
* `#2162` [Accessibility] Required fields MUST be displayed as required - new project_type
* `#2228` [Accessibility] low contrast in backlogs task view
* `#2231` [Accessibility] alt texts for openproject project menu
* `#2240` [Accessibility] correctly label document language of menu items
* `#2250` [Accessibility] activity icon labels
* `#2260` [Accessibility] no-existent alt-text for collapse/expand functionality in grouped work-package list
* `#2263` [Accessibility] Correct markup for tables
* `#2366` [Timelines] Add support for user deletion to timelines
* `#2502` New Layout for overview / my page
* `#2734` [API] Access-Key not supported for all controllers
* `#3065` Fixed internal error when selecting costs-columns and displaying sums in work package list
* `#3120` Implement a test suite the spikes can be developed against
* `#3251` [Timelines] Filtering for Responsible filters everything
* `#3393` [Timelines] Filter Work Packages by Assignee
* `#3401` [Work package tracking] Notes are not saved when copying a work package
* `#3409` New Layout for fallback Login page
* `#3453` Highlight project in bread crumb
* `#3546` Better icon for Timelines Module
* `#3547` Change color of Apply button in Activity
* `#3667` Better icon for Roadmap
* `#3863` Strange additional journal entry when moving work package
* `#3879` Work Package Show: Attachments are shown within attributes table

## 3.0.0pre42

* `#1951` Layout for ## and ### textile link help is broken
* `#2146` [Accessibility] Link form elements to their label - timeline groupings
* `#2147` [Accessibility] Link form elements to their label - new timeline
* `#2150` [Accessibility] Link form elements to their label - new issue query
* `#2151` [Accessibility] Link form elements to their label - new wiki page
* `#2152` [Accessibility] Link form elements to their label - new forum message
* `#2155` [Accessibility] Link form elements to their label - copy workflow
* `#2156` [Accessibility] Link form elements to their label - new custom field
* `#2159` [Accessibility] Link form elements to their label - repository administration
* `#2160` [Accessibility] Link form elements to their label - new LDAP authentication
* `#2161` [Accessibility] Link form elements to their label - new color
* `#2229` [Accessibility] low contrast in calendar view
* `#2244` [Accessibility] correctly label document language - custom fields
* `#2250` [Accessibility] activity icon labels
* `#2258` [Accessibility] linearisation of issue show form
* `#2264` [Accessibility] Table headers for work package hierarchy and relations
* `#2500` Change default configuration in new OpenProject application so new projects are not public by default
* `#3370` [Design] Clean-up and refactoring existing CSS for content area
* `#3528` [Data Migration] Type 'none' is not migrated properly in Timelines
* `#3532` Fix: [API] It is possible to set statuses that are not allowed by the workflow
* `#3539` [Work package tracking] Modul view of work packages is too broad
* `#3666` Fix: [API] Show-action does not contain author_id
* `#3723` Fix: The activity event type of work package creations is resolved as "closed"
* [Accessibility] Reactivate accessibility css; Setting for Accessibility mode for anonymous users
* Fixed workflow copy view
* Add redirect from /wp to /work_packages for less typing

## 3.0.0pre41

* `#2743` Clear work packages filters when the work packages menu item is clicked
* `#3072` Timelines rendering of top table border and text is slightly off
* `#3108` [Work package tracking] Too many users selectable as watchers in public projects
* `#3334` [CodeClimate] Mass Assignment WikiController
* `#3336` Fix: use permitted_params for queries controller
* `#3364` [Performance] Create index on enabled_modules.name
* `#3407` Fix: [Roadmap] Missing dropdown menu for displaying work packages by different criteria
* `#3455` Fix: [Projects] Tab "Types" missing in newly created projects
* `#3245` Fix: Search bar does not display results on a project basis

## 3.0.0pre40

* `#3066` [Work package tracking] Bulk edit causes page not found
* update will paginate

## 3.0.0pre39

* `#3306` Switch to Ruby 2.0
* `#3321` [Data migration] Data in timeline settings not copied to new project
* `#3322` Fix: [Data migration] Journal entries display changes to custom fields
* `#3329` Refactor Duplicated Code Journals

## 3.0.0pre38

* `#2399` Fix: Translation missing (en and de) for not_a_valid_parent
* `#3054` Fix: Some Projects cannot be deleted
* `#3149` Fix: duplicate XML root nodes in API v2 show
* `#3229` Fix: Can't set planning element status
* `#3234` Fix: [Work package tracking] Sorting of work package statuses does not work
* `#3266` Fix: [Work package tracking] % done in work package status cannot be modified
* `#3291` Fix: Internal error when clicking on member
* `#3303` Fix: [Work package tracking] Search results are linked to wrong location
* `#3322` [Data migration] Journal entries display changes to custom fields
* `#3331` use permitted_params for group_controller
* `#3337` Fix: Use permitted params in EnumerationsController
* `#3363` [Timelines] Autocompleter broken multiple times in timelines edit
* `#3390` [Design] Implement new look for header and project navigation
* Change global search keyboard shortcut to 's' and project menu shortcut to 'p'
* Add auto-completion for work-packages in all textareas's with wiki-edit class
* Fixed a small bug with a non-functional validation for parents when creating a work package

## 3.0.0pre37

* `#1966` Select person responsible for project with auto-completion form
* `#2289` Fix: Deploying in a subdirectory
* `#2395` [Work Package Tracking] Internal Error when entering a character in a number field in a filter
* `#2527` Create project has useless responsible field
* `#3091` Both Top menu sides can be open at the same time
* `#3202` Fix: Fix: [Bug] Grouping work packages by responsible is broken
* `#3222` Fix: Validation errors on copying OpenProject

## 3.0.0pre36

* `#3155` Icons from icon font in content area
* Rename German i18n Planungsverantwortlicher -> Verantwortlicher

## 3.0.0pre35

* `#2759` Fix: [Performance] Activity View very slow
* `#3050` Fix: Fix: [Work Package Tracking] Internal error with query from the time before work packages
* `#3104` Fix: [Forums] Number of replies to a topic are not displayed
* `#3202` Fix: [Bug] Grouping work packages by responsible is broken
* `#3212` First Grouping Criteria Selection broken when more than one element pre-selected
* `#3055` [Work Package Tracking] Former deleted planning elements not handled in any way

## 3.0.0pre34

* `#2361` [Timelines] Refactoring of Timelines file structure.
* `#2660` fixed bug
* `#3050` Fix: [Work Package Tracking] Internal error with query from the time before work packages
* `#3040` Fix: [Work Package Tracking] 404 for Work Package Index does not work, results in 500
* `#3111` fixed bug
* `#3193` Fix: [Bug] Copying the project OpenProject results in 500
* Fix position of 'more functions' menu on wp#show
* Fix queries on work packages index if no project is selected
* Fix wiki menu item breadcrumb
* Fixed grammatical error in translation missing warning
* Fixed other user preferences not being saved correctly in cukes
* Settings: Fix work package tab not being shown after save

## 3.0.0pre33

* `#2761` Fix: [Work Package Tracking] Assigning work packages to no target version not working in buld edit
* `#2762` [Work package tracking] Copying a work package in bulk edit mode opens move screen
* `#3021` Fix: Fix: emails sent for own changes
* `#3058` [Work Package Tracking] Broken subtask hierarchy layout
* `#3061` [Timelines] When the anonymous user does not have the right to view a reporting but tries to see a timeline w/ reportings, the error message is wrong
* `#3068` Fix: [Migration] Automatic update text references to planning elements not migrated
* `#3075` Fix: [Work Package Tracking] Save takes too long with many ancestors
* `#3110` Fix: [Migration] Default status not set to right status on planning element migration
* Fix timezone migration for MySQL with custom timezone
* Timeline performance improvements.

## 3.0.0pre32

* `#1718` Invalidate server side sessions on logout
* `#1719` Set X-Frame-Options to same origin
* `#1748` Add option to diable browser cache
* `#2332` [Timelines] Field "planning comparisons" does not check for valid input
* `#2581` Include also end date when sorting workpackges in timelines module
* `#2591` Fix: Costs prevents work package context menu
* `#3018` Fix: Stored queries grouping by attribute is not working
* `#3020` Fix: E-mail Message-ID header is not unique for Work Package mails
* `#3021` Fix: emails sent for own changes
* `#3028` Migration of legacy planning elements doesn't update journals.
* `#3030` Users preferences for order of comments is ignored on wp comments
* `#3032` Fix: Work package comments aren't editable by authors
* `#3038` Fix: Journal changes are recorded for empty text fields
* `#3046` Fix: Edit-form for work package updates does not respect user preference for journal ordering
* `#3057` Fix: [Migration] Missing responsibles
* API v2: Improve timelines performance by not filtering statuses by visible projects
* Add hook so that plugins can register assets, which are loaded on every page
* added missing specs for PR #647


## 3.0.0pre31

* `#313`  Fix: Changing the menu title of a menu wiki page does not work
* `#1368` Fix: Readding project members in user admin view
* `#1961` Sort project by time should only include work packages that are shown within the timeline report
* `#2285` [Agile] [Timelines] Add workpackage custom queries to project menu
* `#2534` Fix: [Forums] Moving topics between boards doesn't work
* `#2653` Remove relative vertical offset corrections and custom border fixes for IE8.
* `#2654` Remove custom font rendering/kerning as well as VML from timelines.
* `#2655` Find a sensible default for Timelines rendering bucket size.
* `#2668` First Grouping Criteria broken when also selecting Hide other group
* `#2699` [Wiki] 400 error when entering special character in wiki title
* `#2706` [Migration] Timeline options does not contain 'none' type
* `#2756` [Work package] 500 when clicking on analyze button in work package summary
* `#2999` [Timelines] Login checks inconsistent w/ public timelines.
* `#3004` Fix: [Calendar] Internal error when selecting more than one type in calendar
* `#3010` Fix: [Calendar] Sprints not displayed properly when start and end date of two sprints are seperate
* `#3016` [Journals] Planning Element update messages not migrated
* `#3033` Fix: Work package update descriptions starting with a h3 are truncated
* Fix mysql data migrations
* Change help url to persistent short url
* Applied new main layout

## 3.0.0pre30

* Redirect old issue links to new work package URIs
* `#2721` Fix: Fix: Fix: Fix: Missing journal entries for customizable_journals
* `#2731` Migrated serialized yaml from syck to psych

## 3.0.0pre29

* `#2473` [Timelines] Tooltip in timeline report shows star * instead of hash # in front of ID
* `#2718` Newlines in workpackage descriptions aren't normalized for change tracking
* `#2721` Fix: Fix: Fix: Missing journal entries for customizable_journals

## 3.0.0pre28

* `#1910` New menu structure for pages of timelines module
* `#2363` When all wiki pages have been deleted new wiki pages cannot be created (respecification)
* `#2566` Fix: [Timelines] Searching when selecting columns for a timeline configuration does not work
* `#2631` Fix: [Timelines] Work package cannot be created out of timeline.
* `#2685` [Work package tracking] 404 when deleting work package priority which is assigned to work package
* `#2686` Fix: [Work package tracking] Work package summary not displayed correctly
* `#2687` Fix: [Work Package Tracking] No error for parallel editing
* `#2708` Fix: API key auth does not work for custom_field actions
* `#2712` Fix: Journal entry on responsible changes displayed as numbers
* `#2715` [Journals] Missing attachable journals
* `#2716` Fix: Repository is not auto-created when activated in project settings
* `#2717` Fix: Multiple journal entries when adding multiple attachments in one change
* `#2721` Fix: Fix: Missing journal entries for customizable_journals
* Add indices to to all the journals (improves at least WorkPackage show)
* Improve settings performance by caching whether the settings table exists

## 3.0.0pre27

* `#416`  Fix: Too many users selectable as watchers
* `#2697` Fix: Missing migration of planning element watchers
* `#2564` Support custom fields in REST API v2 for work packages and projects
* `#2567` [Timelines] Select2 selection shows double escaped character
* `#2586` Query available custom fields in REST API v2
* `#2637` Migrated timestamps to UTC
* `#2696` CustomValues still associated to issues
* Reverts `#2645` Remove usage of eval()
* Fix work package filter query validations

## 3.0.0pre26

* `#2624` [Journals] Fix: Work package journals that migrated from legacy planning elements lack default references
* `#2642` [Migration] Empty timelines options cannot be migrated
* `#2645` Remove usage of eval()
* `#2585` Special characters in wiki page title

## 3.0.0pre25

* `#2515` Fix: Calendar does not support 1st of December
* `#2574` Fix: Invalid filter options and outdated names in timeline report form
* `#2613` Old IE versions (IE 7 & IE 8) are presented a message informing about the incompatibilities.
* `#2615` Fix board edit validations
* `#2617` Fix: Timelines do not load users for non-admins.
* `#2618` Fix: When issues are renamed to work packages all watcher assignments are lost
* `#2623` [Journals] Images in journal notes are not displayed
* `#2624` [Journals] Work package journals that migrated from legacy planning elements lack default references.
* `#2625` [Membership] Page not found when editing member and display more pages
* Improved newline handling for journals
* Improved custom field comparison for journals
* Respect journal data serialized with legacy YAML engine 'syck'

## 3.0.0pre24

* `#2593` Work Package Summary missing
* `#1749` Prevent JSON Hijacking
* `#2281` The context menu is not correctly displayed
* `#2348` [Timelines] Using planning element filter and filtering for status "New" leads always to plus-sign in front of work packages
* `#2357` [Timelines] Change API v2 serialization to minimize redundant data
* `#2363` When all wiki pages have been deleted new wiki pages cannot be created
* `#2380` [Timelines] Change API v2 serialization to maximize concatenation speed
* `#2420` Migrate the remaining views of api/v2 to rabl
* `#2478` Timeline with lots of work packages doesn`t load
* `#2525` Project Settings: Forums: Move up/down result in 404
* `#2535` [Forum] Atom feed on the forum's overview-page doesn't work
* `#2576` [Timelines] Double scrollbar in modal for Chrome
* `#2577` [Timelines] Users are not displayed in timelines table after recent API version
* `#2579` [Core] Report of spent time (without cost reporting) results in 404
* `#2580` Fixed some unlikely remote code executions
* `#2592` Search: Clicking on 'Next' results in 500
* `#2593` Work Package Summary missing
* `#2596` [Roadmap] Closed tickets are not striked out
* `#2597` [Roadmap] Missing english/german closed percentage label
* `#2604` [Migration] Attachable journals incorrect
* `#2608` [Activity] Clicking on Atom-feed in activity leads to 500 error
* `#2598` Add rake task for changing timestamps in the database to UTC

## 3.0.0pre23

* `#165`  [Work Package Tracking] Self-referencing ticket breaks ticket
* `#709`  Added test for double custom field validation error messages
* `#902`  Spelling Mistake: Timelines Report Configuration
* `#959`  Too many available responsibles returned for filtering in Timelines
* `#1738` Forum problem when no description given.
* `#1916` Work package update screen is closed when attached file is deleted
* `#1935` Fixed bug: Default submenu for wiki pages is wrong (Configure menu item)
* `#2009` No journal entry created for attachments if the attachment is added on container creation
* `#2026` 404 error when letters are entered in category Work Package
* `#2129` Repository: clicking on file results in 500
* `#2221` [Accessibility] enhance keyboard shortcuts
* `#2371` Add support for IE10 to Timelines
* `#2400` Cannot delete work package
* `#2423` [Issue Tracker] Several Internal Errors when there is no default work package status
* `#2426` [Core] Enumerations for planning elements
* `#2427` [Issue Tracker] Cannot delete work package priority
* `#2433` [Timelines] Empty timeline report not displayed initially
* `#2448` Accelerate work package updates
* `#2464` No initial attachment journal for messages
* `#2470` [Timelines] Vertical planning elements which are not displayed horizontally are not shown in timeline report
* `#2479` Remove TinyMCE spike
* `#2508` Migrated former user passwords (from OpenProject 2.x strong_passwords plugin)
* `#2521` XSS: MyPage on unfiltered WorkPackage Subject
* `#2548` Migrated core settings
* `#2557` Highlight changes of any work package attribute available in the timelines table
* `#2559` Migrate existing IssueCustomFields to WorkPackageCustomFields
* `#2575` Regular expressions should use \A and \z instead of ^ and $
* Fix compatibility with old mail configuration

## 3.0.0pre22

* `#1348` User status has no database index
* `#1854` Breadcrumbs arrows missing in Chrome
* `#1935` Default submenu for wiki pages is wrong (Configure menu item)
* `#1991` Migrate text references to issues/planning elements
* `#2297` Fix APIv2 for planning elements
* `#2304` Introduce keyboard shortcuts
* `#2334` Deselecting all types in project configuration creates 500
* `#2336` Cukes for timelines start/end date comparison
* `#2340` Develop migration mechanism for renamed plugins
* `#2374` Refactoring of ReportsController
* `#2383` [Performance] planning_elements_controller still has an n+1-query for the responsible
* `#2384` Replace bundles svg graph with gem
* `#2386` Remove timelines_journals_helper
* `#2418` Migrate to RABL
* Allow using environment variables instead of configuration.yml

## 3.0.0pre21

* `#1281` I18n.js Not working correctly. Always returns English Translations
* `#1758` Migrate functional-tests for issues into specs for work package
* `#1771` Fixed bug: Refactor Types Project Settings into new Tab
* `#1880` Re-introduce at-time scope
* `#1881` Re-introduce project planning comparison in controller
* `#1883` Extend at-time scope for status comparison
* `#1884` Make status values available over API
* `#1994` Integrational tests for work packages at_time (API)
* `#2070` Settle copyright for images
* `#2158` Work Package General Setting
* `#2173` Adapt client-side to new server behavior
* `#2306` Migrate issues controller tests
* `#2307` Change icon of home button in header from OpenProjct icon to house icon
* `#2310` Add proper indices to work_package
* `#2319` Add a request-store to avoid redundant calls

## 3.0.0pre20

* `#1560` WorkPackage/update does not retain some fields when validations fail
* `#1771` Refactor Types Project Settings into new Tab
* `#1878` Project Plan Comparison(server-side implementation): api/v2 can now resolve historical data for work_packages
* `#1929` Too many lines in work package view
* `#1946` Modal shown within in Modal
* `#1949` External links within modals do not work
* `#1992` Prepare schema migrations table
* `#2125` All AJAX actions on work package not working after update
* `#2237` Migrate reports controller tests
* `#2246` Migrate issue categories controller tests
* `#2262` Migrate issue statuses controller tests
* `#2267` Rename view issue hooks

## 3.0.0pre19

* `#2055` More dynamic attribute determination for journals for extending journals by plugins
* `#2203` Use server-side responsible filter
* `#2204` Implement server-side status filter.
* `#2218` Migrate context menus controller tests

## 3.0.0pre18

* `#1715` Group assigned work packages
* `#1770` New Comment Section layout errors
* `#1790` Fix activity view bug coming up during the meeting adaptions to acts_as_journalized
* `#1793` Data Migration Journals
* `#1977` Set default type for planning elements
* `#1990` Migrate issue relation
* `#1997` Migrate journal activities
* `#2008` Migrate attachments
* `#2083` Extend APIv2 to evaluate filter arguments
* `#2087` Write tests for server-side type filter
* `#2088` Implement server-side filter for type
* `#2101` 500 on filtering multiple values
* `#2104` Handle incomplete trees on server-side
* `#2105` Call PE-API with type filters
* `#2138` Add responsible to workpackage-search

## 3.0.0pre17

* `#1323` Wrong Calendarweek in Datepicker, replaced built in datepicker with jQuery UI datepicker
* `#1843` Editing Membership Duration in admin area fails
* `#1913` [Timelines] Enable drag&drop for select2 items in order to rearrange the order of the columns
* `#1934` [Timelines] Table Loading takes really long
* `#1978` Migrate legacy issues
* `#1979` Migrate legacy planning elements
* `#1982` Migrate planning element types
* `#1983` Migrate queries
* `#1987` Migrate user rights
* `#1988` Migrate settings
* `#2019` Migrate auto completes controller tests
* `#2078` Work package query produces 500 when grouping on exclusively empty values

## 3.0.0pre16

* `#1418` Additional changes: Change links to issues/planning elements to use work_packages controller
* `#1504` Initial selection of possible project members wrong (accessibility mode)
* `#1695` Cannot open links in Projects menu in new tab/window
* `#1753` Remove Issue and replace with Work Package
* `#1754` Migrate unit-tests for issues into specs for work_package
* `#1757` Rename Issues fixtures to Work Package fixtures
* `#1759` Remove link_to_issue_preview, replace with link_to_workpackage_preview
* `#1822` Replace Issue constant by WorkPackage constant
* `#1850` Disable atom feeds via setting
* `#1874` Move Scopes from Issue into Workpackage
* `#1898` Separate action for changing wiki parent page (was same as rename before)
* `#1921` Allow disabling done ratio for work packages
* `#1923` Add permission that allows hiding repository statistics on commits per author
* `#1950` Grey line near the lower end of the modal, cuts off a bit of the content

## 3.0.0pre15

* `#1301` Ajax call when logged out should open a popup window
* `#1351` Generalize Modal Creation
* `#1557` Timeline Report Selection Not Visible
* `#1755` Migrate helper-tests for issues into specs for work package
* `#1766` Fixed bug: Viewing diff of Work Package description results in error 500
* `#1767` Fixed bug: Viewing changesets results in "page not found"
* `#1789` Move validation to Work Package
* `#1800` Add settings to change software name and URL and add additional footer content
* `#1808` Add option to log user for each request
* `#1875` Added test steps to reuse steps for my page, my project page, and documents, no my page block lookup at class load time
* `#1876` Timelines do not show work packages when there is no status reporting
* `#1896` Moved visibility-tests for issues into specs for workpackages
* `#1911` Change mouse icon when hovering over drag&drop-enabled select2 entries
* `#1912` Merge column project type with column planning element type
* `#1918` Custom fields are not displayed when issue is created

## 3.0.0pre14

* `#825`  Migrate Duration
* `#828`  Remove Alternate Dates
* `#1421` Adapt issue created/updated wording to apply to work packages
* `#1610` Move Planning Element Controller to API V2
* `#1686` Issues not accessible in public projects when not a member
* `#1768` Fixed bug: Klicking on Wiki Edit Activity results in error 500
* `#1787` Remove Scenarios
* `#1813` Run Data Generator on old AAJ schema
* `#1859` Fix 20130814130142 down-migration (remove_documents)
* `#1873` Move Validations from Issue into Workpackage

## 3.0.0pre13

* `#1606` Update journal fixtures
* `#1608` Change activities to use the new journals
* `#1609` Change search to use the new journals
* `#1616` Serialization/Persistence
* `#1617` Migrate database to new journalization
* `#1724` PDF Export of Work Packages with Description
* `#1731` Squash old migrations into one

## 3.0.0pre12

* `#1417` Enable default behavior for types
* `#1631` Remove documents from core

## 3.0.0pre11

* `#1418` Change links to issues/planning elements to use work_packages controller
* `#1541` Use Rails 3.2.14 instead of Git Branch
* `#1595` Cleanup action menu for work packages
* `#1596` Copy/Move work packages between projects
* `#1598` Switching type of work package looses inserted data
* `#1618` Deactivate modal dialogs and respective cukes
* `#1637` Removed files module
* `#1648` Arbitrarily failing cuke: Navigating to the timeline page

## 3.0.0pre10

* `#1246` Implement uniform "edit" action/view for pe & issues
* `#1247` Implement uniform "update" action for pe & issues
* `#1411` Migrate database tables into the new model
* `#1413` Ensure Permissions still apply to the new Type
* `#1425` Remove default planning element types in favor of enabled planning element types in the style of has_and_belongs_to_many.
* `#1427` Enable API with the new Type
* `#1434` Type controller
* `#1435` Type model
* `#1436` Type views
* `#1437` Update seed data
* `#1512` Merge PlanningElementTypes model with Types model
* `#1520` PlanningElements are created without the root_id attribute being set
* `#1520` PlanningElements are created without the root_id attribute being set
* `#1536` Fixed bug: Reposman.rb receives xml response for json request
* `#1577` Searching for project member candidates is only possible when using "firstname lastname" (or parts of it)

## 3.0.0pre9

* `#779`  Integrate password expiration
* `#1314` Always set last activity timestamp and check session expiry if ttl-setting is enabled
* `#1371` Changing pagination per_page_param does not change page
* `#1405` Incorrect message when trying to login with a permanently blocked account
* `#1409` Changing pagination limit on members view looses members tab
* `#1414` Remove start & due date requirement from planning elements
* `#1461` Integration Activity Plugin
* `#1488` Fixes multiple and missing error messages on project settings' member tab (now with support for success messages)
* `#1493` Exporting work packages to pdf returns 406
* `#1505` Removing all roles from a membership removes the project membership
* `#1517` Journal changed_data cannot contain the changes of a wiki_content content

## 3.0.0pre8

* `#377`  Some usability fixes for members selection with select2
* `#1024` Add 'assign random password' option to user settings
* `#1063` Added helper to format the time as a date in the current user or the system time zone
* `#1391` Opening the new issue form in a project with an issue category defined produces 500 response
* `#1406` Creating a work package w/o responsible or assignee results in 500
* `#1420` Allow for seeing work package description changes inside of the page
* `#1488` Fixes multiple and missing error messages on project settings' member tab

## 3.0.0pre7

* `#778` Integrate ban of former passwords
* `#780` Add password brute force prevention
* `#820` Implement awesome nested set on work packages
* `#1034` Create changelog and document format
* `#1119` Creates a unified view for work_package show, new and create
* `#1209` Fix adding watcher to issue
* `#1214` Fix pagination label and 'entries_per_page' setting
* `#1299` Refactor user status
* `#1301` Ajax call when logged out should open a popup window
* `#1303` Watcherlist contains unescaped HTML
* `#1315` Correct spelling mistakes in German translation

