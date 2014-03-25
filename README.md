# OpenProject Webhooks Plugin

`openproject-webhooks` is an OpenProject plugin, which adds a webhook API to OpenProject. Other plugins may build upon this plugin to implement their functionality.

External services like GitHub or Travis could be integrated with the help of this plugin.

**Note:** This is an infrastructure-only plugin. With this plugin alone, you will not notice any difference in your OpenProject installation.

## Requirements

* OpenProject version **3.1.0 or higher** ( or a current installation from the `dev` branch)

## Installation and Setup:

This is an OpenProject plugin, thus we follow the usual OpenProject plugin installation mechanism.
Because we depend on the [`openproject-webhooks`](https://github.com/finnlabs/openproject-webhooks) plugin, we also install that plugin.

### Plugin Installation

Edit the `Gemfile.plugins` file in your openproject-installation directory to contain the following lines:

<pre>
gem "openproject-webhooks", :git => 'https://github.com/finnlabs/openproject-github_integration.git', :branch => 'stable'
</pre>

Then update your bundle with:

<pre>
bundle install
</pre>

and restart the OpenProject server.

## Get in Contact

OpenProject is supported by its community members, both companies as well as individuals. There are different possibilities of getting help:
* OpenProject [support page](https://www.openproject.org/projects/openproject/wiki/Support)
* E-Mail Support - info@openproject.org

## Start Collaborating

Join the OpenProject community and start collaborating. We envision building a platform to share ideas, contributions, and discussions around OpenProject and project collaboration. Each commitment is noteworthy as it helps to improve the software and the project.
More details will be added on the OpenProject Community [contribution page](https://www.openproject.org/projects/openproject/wiki/Contribution).

In case you find a bug or need a feature, please report at https://www.openproject.org/projects/webhooks/work_packages

## License

Copyright (C) 2014 the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md for details.
