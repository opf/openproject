<!---- copyright
OpenProject is a project management system.

Copyright (C) 2012-2013 the OpenProject Team

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License version 3.

See doc/COPYRIGHT.md for more details.

++-->

# OpenProject Plugins Plugin

This plugin aims to make writing plugins easier. It provides a generator for creating a basic plugin structure and a module that simplifies setting up the plugin Rails engine. Thus, it is also a dependency for many plugins.

## Usage

Make sure to include the plugins plugin before all other plugins in your Gemfile, otherwise the module used by the plugin Rails engines (`OpenProject::Plugins::ActsAsOpEngine`) is not available when a plugin is being loaded.

### Generator

    bundle exec rails generate open_project:plugin <plugin name> <target folder>

The generator will create a new subfolder within `<target folder>`, named `openproject-<plugin name>`.

Example:

    bundle exec rails generate open_project:plugin xls_export .

### ActsAsOpEngine

The generated engine uses `ActsAsOpEngine` by default, so just have a look at this file.
For more information on how to use `ActsAsOpEngine`, just see the comments in its [source code](lib/open_project/plugins/acts_as_op_engine.rb).
It offers methods to load patches and register assets besides others.

#### Example
```ruby
module OpenProject::RepositoryAuthentication
  class Engine < ::Rails::Engine
    engine_name :openproject_repository_authentication

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-repository_authentication',
             :author_url => 'http://finn.de',
             :requires_openproject => '>= 3.0.0pre6'

    patches [:SysController]
  end
end
```

## Get in Contact

OpenProject is supported by its community members, both companies as well as individuals. There are different possibilities of getting help:
* OpenProject [support page](https://www.openproject.org/projects/openproject/wiki/Support)
* E-Mail Support - info@openproject.org

## Start Collaborating

Join the OpenProject community and start collaborating. We envision building a platform to share ideas, contributions, and discussions around OpenProject and project collaboration. Each commitment is noteworthy as it helps to improve the software and the project.
More details will be added on the OpenProject Community [contribution page](https://www.openproject.org/projects/openproject/wiki/Contribution).

In case you find a bug or need a feature, please report at https://www.openproject.org/projects/plugin-plugins/issues

## License

(c) 2013 - Finn GmbH

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md for details.
