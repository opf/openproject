# OpenProject Webhooks Plugin

`openproject-webhooks` is an OpenProject plugin, which adds a webhook API to OpenProject. Other plugins may build upon this plugin to implement their functionality.

External services like [GitHub](https://github.com/finnlabs/openproject-github_integration) or Travis could be integrated with the help of this plugin.

**Note:** This is an infrastructure-only plugin. With this plugin alone, you will not notice any difference in your OpenProject installation.

## Installation

This is an OpenProject plugin, thus we follow the usual OpenProject plugin installation mechanism.

### Requirements

* OpenProject version **3.1.0 or higher** ( or a current installation from the `dev` branch)

### Plugin Installation

Edit the `Gemfile.plugins` file in your openproject-installation directory to contain the following lines:

<pre>
gem "openproject-webhooks", :git => 'https://github.com/finnlabs/openproject-webhooks.git', :branch => 'stable'
</pre>

Then update your bundle with:

<pre>
bundle install
</pre>

and restart the OpenProject server.

## Contact

OpenProject is supported by its community members, both companies and individuals.

Please find ways to contact us on the OpenProject [support page](https://www.openproject.org/support).

## Contributing

This OpenProject plugin is an open source project and we encourage you to help us out. We'd be happy if you do one of these things:

* Create a new [work package in the Webhooks plugin project on openproject.org](https://www.openproject.org/projects/webhooks/work_packages) if you find a bug or need a feature
* Help out other people on our [forums](https://www.openproject.org/projects/openproject/boards)
* Help us [translate this plugin to more languages](https://www.openproject.org/projects/openproject/wiki/Translations)
* Contribute code via GitHub Pull Requests, see our [contribution page](https://www.openproject.org/projects/openproject/wiki/Contribution) for more information

## Community

OpenProject is driven by an active group of open source enthusiasts: software engineers, project managers, creatives, and consultants. OpenProject is supported by companies as well as individuals. We share the vision to build great open source project collaboration software.
The [OpenProject Foundation (OPF)](https://www.openproject.org/projects/openproject/wiki/OpenProject_Foundation) will give official guidance to the project and the community and oversees contributions and decisions.

## Repository

This repository contains two main branches:

* `dev`: The main development branch. We try to keep it stable in the sense of all tests are passing, but we don't recommend it for production systems.
* `stable`: Contains the latest stable release that we recommend for production use. Use this if you always want the latest version of this plugin.

## License

Copyright (C) 2014 the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See [doc/COPYRIGHT.md](doc/COPYRIGHT.md) for details.
