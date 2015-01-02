<!---- copyright
OpenProject is a project management system.
Copyright (C) 2012-2015 the OpenProject Foundation (OPF)

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

# Developing OpenProject Plugins

The core functionality of OpenProject may be extended through the use of plugins.

## Rails/backend plugins

Plugins that extend the Rails application are packaged as **Ruby gems**.
These plugins must contain a `Gem::Specification` (typically as a `.gemspec`
file in the root directory of the plugin).

**To use a Rails plugin**

  * declare the dependency in `Gemfile.plugins` within the `:opf_plugins` group
    using the Bundler DSL.

    Example:

    ```ruby
    group :opf_plugins do
      gem :openproject_costs, git: 'https://github.com/finnlabs/openproject-backlogs.git', branch: 'dev'
    end
    ```

  * run `bundle install`.

## Frontend plugins [WIP]

Plugins that extend the frontend application may be packaged as **npm modules**.
These plugins must contain a `package.json` in the root directory of the plugin.

Plugins are responsible for loading their own assets, including additional
images, styles and I18n translations.

To load translation strings use the provided `I18n.addTranslation` function:

    ```js
    I18n.addTranslations('en', require('../../config/locales/js-en.yml').en);
    ```

Pure frontend plugins should be considered _a work in progress_. As such, it is
currently recommended to create hybrid plugins (see below).

**To use a frontend plugin:**

  * You will currently need to modify the `package.json` of OpenProject core
    directly. A more robust solution is currently in planning.

## Hybrid plugins

Plugins that extend both the Rails and frontend applications are possible. They
must contain both a `Gem::Specification` and `package.json`.

_CAVEAT: npm dependencies for hybrid plugins are not yet resolved._

**To use a hybrid plugin:**

  * declare the dependency in `Gemfile.plugins` within the `:opf_plugins` group
    using the Bundler DSL.

  * then run `bundle install`.

You **do not** need to modify the `package.json` of OpenProject core. Provided
Ruby Bundler is aware of these plugins, Webpack (our node-based build pipeline)
will bundle their assets.
