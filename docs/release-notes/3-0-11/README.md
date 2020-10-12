---
  title: OpenProject 3.0.11
  sidebar_navigation:
      title: 3.0.11
  release_version: 3.0.11
  release_date: 2014-11-04
---


# OpenProject 3.0.11

The release 3.0.11 of OpenProject fixes a couple of security threats
([\#5567](https://community.openproject.org/work_packages/5567 "[security] fixed back url verification (closed)")
and
[\#14782](https://community.openproject.org/work_packages/14782 "Disable redirection to a different subdirectory after login (closed)"))
and raises the Rails version to
[3.2.19](http://weblog.rubyonrails.org/2014/7/2/Rails_3_2_19_4_0_7_and_4_1_3_have_been_released/).
So we advise everybody to update their OpenProject installation.

When doing so you also benefit from a couple of usability bugfixes. Most
notably, the preview functionality now works again throughout the
application
([\#14775](https://community.openproject.org/work_packages/14775 "Preview not working for new forum messages (closed)"))
and if you are using the the [backlogs
plugin](https://github.com/finnlabs/openproject-backlogs) it now shows
the story points in the work package page
([\#7922](https://community.openproject.org/work_packages/7922 "Story Points not visible in WP Show (closed)")).

With the integration of the repository-authentication plugin into
OpenProject
([\#14783](https://community.openproject.org/work_packages/14783 "Port whole functionality of openproject-repository_authentication into the core (closed)")),
it is now once again possible to manage authentication and authorisation
of SVN repositories with OpenProject. The same will be allowed for Git
repositories with OpenProject 4.0
([\#3708](https://community.openproject.org/work_packages/3708 "Release OpenProject 4.0 (closed)")).

For a complete list of changes, please refere to the [OpenProject 3.0.11
query](https://community.openproject.org/versions/423).


