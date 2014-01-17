<!---- copyright
OpenProject is a project management system.

Copyright (C) 2012-2013 the OpenProject Foundation (OPF)

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
             :requires_openproject => '>= 3.0.0pre6' do
      menu :project_menu,
           :repo_auth,
           {:controller => '/repo_auth_controller', :action => :index},
           :caption => "Repo Auth!"
    end

    patches [:SysController]
  end
end
```

## Caveats

### db:create and db:migrate

When using OpenProject plugins, you can't use the `db:create` and `db:migrate` within one rake process, i.e. `rake db:create db:migrate` will not work. It would only run core migrations, but not plugin migrations.

Here's an explanation for this behavior:

> db:create invokes db:load_config. db:load_config collects migration paths, but the
> migration paths for plugins are set on the Engine config when the application
> is initialized, which the environment task does. The environment task is only later
> executed as dependency for db:migrate. db:migrate also depends on load_config, but since
> it has been executed before, rake doesn't execute it a second time.
> Loading the environment bevore explicitly executing db:load_config (not only invoking it)
> makes rake execute it a second time after the environment has been loaded.
> Loading the environment before db:create does not work, since initializing the application
> depends on an existing databse.

## Get in Contact

OpenProject is supported by its community members, both companies as well as individuals. There are different possibilities of getting help:
* OpenProject [support page](https://www.openproject.org/projects/openproject/wiki/Support)
* E-Mail Support - info@openproject.org

## Start Collaborating

Join the OpenProject community and start collaborating. We envision building a platform to share ideas, contributions, and discussions around OpenProject and project collaboration. Each commitment is noteworthy as it helps to improve the software and the project.
More details will be added on the OpenProject Community [contribution page](https://www.openproject.org/projects/openproject/wiki/Contribution).

In case you find a bug or need a feature, please report at https://www.openproject.org/projects/plugin-plugins/issues

## License

Copyright (C) 2013 the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md for details.
