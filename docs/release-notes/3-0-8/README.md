---
  title: OpenProject 3.0.8
  sidebar_navigation:
      title: 3.0.8
  release_version: 3.0.8
  release_date: 2014-11-04
---


# OpenProject 3.0.8

The [3.0.8 bugfix release of
OpenProject](https://github.com/opf/openproject/tree/v3.0.8) addresses a
variety of bugs from filtering
([\#7169](https://community.openproject.org/work_packages/7169 "Filtering for assignee's role returns wrong results (closed)"))
to accessibility
([\#10834](https://community.openproject.org/work_packages/10834 "Some links are readout before the header (closed)"))
and performance limitations when copying projects
([\#12299](https://community.openproject.org/work_packages/12299 "App server blocked when copying large project (closed)")).
For the later, delayed job is employed to ensure that the app server
will still answer while large projects are copied. Please bear in mind
that for this to happen you need to have [delayed job
running](https://github.com/collectiveidea/delayed_job).

For a complete list of changes to OpenProject, please refer to the
[version’s
packages](https://community.openproject.com/projects/openproject/roadmap).

However, this is only half of the truth. With the OpenProject 3.0.8
release we chose to alter our release process. While the changes for the
release process of OpenProject itself are minor, you will notice that
the [plugins listed on
OpenProject.org](http://openproject.org/projects/plugins) now all have
3.0.8 as their most recent version. This was done with the intend of
easing deployment. Subsequent releases will follow this schema as well.
It is our commitment to ensure that plugins with a specific release
number (e.g. 3.0.8) will work flawlessly with an OpenProject of the same
number. We therefore encourage you to always update OpenProject and
installed plugins to the same release in synch. The most easy way of
doing this is to follow the stable branches for every plugin and
OpenProject.

We are aware that this change in versioning has some weird side effects.
The most noticeable is the [costs
plugin](https://github.com/finnlabs/openproject-costs) falling back from
version 5.0.4 to 3.0.8. While this might be confusing, we are convinced
that keeping versions in lockstep will convey the intended compatibility
much better than every other mechanism.


