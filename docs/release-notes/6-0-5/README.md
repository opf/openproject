---
  title: OpenProject 6.0.5
  sidebar_navigation:
      title: 6.0.5
  release_version: 6.0.5
  release_date: 2016-10-18
---


# OpenProject 6.0.5

OpenProject 6.0.5 contains several bug fixes and improvements.

**The following bugs have been fixed in OpenProject 6.0.5:**

  - Work packages
      - Links in the parent column in the work package list were not
        correctly displayed but showed an error
        ([\#23865](https://community.openproject.com/work_packages/23865/activity)).
      - The grouping of work packages was lost on export.
      - In work package custom fields the zero was displayed as not set
        (“-“)
        ([\#23975](https://community.openproject.com/work_packages/23975/activity)).
      - The right-click context menu on the work package list did not
        disappear when clicking an a work package ID or on attribute
        fields
        ([\#24005](https://community.openproject.com/work_packages/24005/activity)).
      - For users who were not allowed to make changes to work packages
        the attachment delete icon and the work package edit button was
        shown
        ([\#24032](https://community.openproject.com/work_packages/24032/activity)).
      - Custom fields of type “Long text” could sometimes not be saved,
        showed distracting icons on hover and were not accessible
        ([\#24033](https://community.openproject.com/work_packages/24033/activity)).
      - Curly braces in the work package description (e.g. to show code)
        were incorrectly displayed / escaped
        ([\#24050](https://community.openproject.com/work_packages/24050/activity)).
      - It was not possible to set the default “Objects per page” for
        the work package list
        ([\#23846](https://community.openproject.com/work_packages/23846/activity)).
      - There was a translation missing when displaying changes in the
        work package description
        ([\#23917](https://community.openproject.com/work_packages/23917/activity)).
  - <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-8">Wiki</span>
      - An internal error occurred when renaming wiki pages to certain
        reserved names
        ([\#23961](https://community.openproject.com/work_packages/23961/activity)).
      - The macro list on the wiki page showed wrong entries / was not
        correctly escaped
        ([\#23835](https://community.openproject.com/work_packages/23835/activity)).
  - Users
      - New users who created a hosted OpenProject instance had wrong
        email settings
        ([\#23856](https://community.openproject.com/work_packages/23856/activity)).
  - <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-37">Repository</span>
      - There was an instance when the Git repository was producing an
        error 500
        ([\#23953](https://community.openproject.com/work_packages/23953/activity)).
      - <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-37">Repository</span>
        commit which referenced work packages were not shown on the work
        package
        ([\#24026](https://community.openproject.com/work_packages/24026/activity)).
  - Costs / Budgets
      - The actual costs for the different entries were not shown in a
        budget
        ([\#24017](https://community.openproject.com/work_packages/24017/activity)).
  - Cost report
      - The scrollbar for the cost report table was missing which made
        it impossible to see large reports
        ([\#23991](https://community.openproject.com/work_packages/23991/activity)).
      - An error occurred when using the cost report with Chinese
        language settings due to a missing translation
        ([\#23998](https://community.openproject.com/work_packages/23998/activity)).
  - <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-92">Backlogs</span>
      - Clicking on an empty story point field in the backlogs to assign
        story points to a work package was not possible
        ([\#23994](https://community.openproject.com/work_packages/23994/activity)).
  - Other
      - There were several design issues and improvements
        ([\#23868](https://community.openproject.com/work_packages/23868/activity),
        [\#23916](https://community.openproject.com/work_packages/23916/activity),
        [\#23925](https://community.openproject.com/work_packages/23925/activity),
        [\#23948](https://community.openproject.com/work_packages/23948/activity),
        [\#23977](https://community.openproject.com/work_packages/23977/activity),
        [\#23978](https://community.openproject.com/work_packages/23978/activity),
        [\#23980](https://community.openproject.com/work_packages/23980/activity),
        [\#23989](https://community.openproject.com/work_packages/23989/activity),
        [\#23992](https://community.openproject.com/work_packages/23992/activity)).

In addition the link to see and edit the logged time has been added to
the work package list and work package page
([\#24023](https://community.openproject.com/work_packages/24023/activity)).

Thanks a lot to the community, in particular to Marc Vollmer, Frank
Schmid, Melroy van den Berg, Richard Su, Mikhail Podshivalin, Tilo
Laufer, Artur Kokhansky, Martin Kleehaus, Filipe Dias, and Markus
Berthold  for [reporting
bugs](https://www.openproject.org/development/report-a-bug/)\!

For further information on the release, please refer to the [Changelog
v.6.0.5](https://community.openproject.com/versions/817) or take a look
at [GitHub](https://github.com/opf/openproject/tree/v6.0.5).

You can try OpenProject for free. For a free 30 day trial create your
OpenProject instance on [OpenProject.org](https://openproject.org/).


