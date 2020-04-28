---
  title: OpenProject 6.1.1
  sidebar_navigation:
      title: 6.1.1
  release_version: 6.1.1
  release_date: 2016-11-29
---


# OpenProject 6.1.1

OpenProject 6.1.1 contains several bug fixes and improvements.

**The following bugs have been fixed in OpenProject 6.1.1:**

  - Work packages
      - Watchers could not be selected in projects with too many
        possible watchers
        ([\#24263](https://community.openproject.com/work_packages/24263/activity)).
      - The wrong sum was shown for “Spent time” for work packages
        ([\#24349](https://community.openproject.com/projects/openproject/work_packages/24349/activity)).
      - The links in the relation tab caused a hard reload instead of
        simply showing the related work package
        ([\#24265](https://community.openproject.com/work_packages/24265/activity)).
      - Textile \<pre\> and @ did not prevent code execution in the work
        package description.
      - The “Spent time” link on the work package list caused an error
        404 in subfolder installations
        ([\#24427](https://community.openproject.com/projects/openproject/work_packages/24427/activity)).
      - Line breaks were not displayed in the work package description
        ([\#24428](https://community.openproject.com/projects/openproject/work_packages/24428/activity)).
  - <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-17">Timeline</span>
      - Timelines which were displayed in aggregation were not shown
        when loaded initially.
  - Projects
      - Projects could not be copied
        ([\#24323](https://community.openproject.com/projects/openproject/work_packages/24323/activity)).
  - Search
      - The search displayed only case-sensitive results
        ([\#24282](https://community.openproject.com/work_packages/24282/activity)).
      - The pagination in the search results was broken
        ([\#24345](https://community.openproject.com/projects/openproject/work_packages/24345/activity)).
  - Other
      - A deprecation warning was displayed whenever a cronjob for
        incoming emails was invoked
        ([\#24306](https://community.openproject.com/projects/openproject/work_packages/24306/activity)).
      - Several design bugs have been fixed
        ([\#24263](https://community.openproject.com/work_packages/24263/activity),
        [\#24274](https://community.openproject.com/work_packages/24274/activity),
        [\#24286](https://community.openproject.com/work_packages/24286/activity),
        [\#24289](https://community.openproject.com/work_packages/24289/activity),
        [\#24297](https://community.openproject.com/work_packages/24297/activity),
        [\#24301](https://community.openproject.com/work_packages/24301/activity),
        [\#24334](https://community.openproject.com/projects/openproject/work_packages/24334/activity),
        [\#24335](https://community.openproject.com/projects/openproject/work_packages/24335/activity),
        [\#24339](https://community.openproject.com/projects/openproject/work_packages/24339/activity),
        [\#24372](https://community.openproject.com/projects/openproject/work_packages/24372/activity),
        [\#24373](https://community.openproject.com/projects/openproject/work_packages/24373/activity)).

Thanks a lot to the community, in particular to Marc Vollmer, Markus
Hillenbrand, Nicolai Daniel and Christophe Mornet for [reporting
bugs](https://www.openproject.org/development/report-a-bug/)\!

For further information on the release, please refer to the [Changelog
v.6.1.1](https://community.openproject.com/versions/821) or take a look
at [GitHub](https://github.com/opf/openproject/tree/v6.1.1).

You can try OpenProject for free. For a free 30 day trial create your
OpenProject instance on [OpenProject.org](https://openproject.org/).


