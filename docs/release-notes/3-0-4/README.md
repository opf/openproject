---
  title: OpenProject 3.0.4
  sidebar_navigation:
      title: 3.0.4
  release_version: 3.0.4
  release_date: 2014-11-04
---


# OpenProject 3.0.4

The most important changes in OpenProject 3.0.4 are the fix to the
`reposman` (see
[`extra/svn/reposman.rb`](https://github.com/opf/openproject/blob/dev/extra/svn/reposman.rb#L103))
script and fixes for making OpenProject subfolder installations less of
a hassle.

The `reposman` script was setting the wrong file (system) permissions
for private repositories, which resulted in public and private
repositories to always have the same file (system) permissions defined.

We also incorporated some changes to make subfolder installations easier
and to behave more like you would expect it to work. From now on it is
possible to just edit the configuration (see
[`config/configuration.yml`](https://github.com/opf/openproject/blob/dev/config/configuration.yml.example#L122))
and set the `rails_relative_url_root` parameter to a proper value and
the installation should work. There is no need to change the`config.ru`
file or other configurations anymore. Regardless of whether you are
using passenger or any other application server.

For a full list of fixes we made please see the [changelog
v 3.0.4](https://community.openproject.com/versions/316)


