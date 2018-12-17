# OpenProject Github Integration Plugin

`openproject-github_integration` is an OpenProject plugin, which aims to integrate GitHub code repositories and a pull request workflow with OpenProject.


![GitHub Integration Screenshot](doc/screenshot.png?raw=true)

Currently we support the following workflow. When you create a pull request and paste a work package URL (or the special marker `OP#<Work package id>` (e.g., `OP#1234`) into its description, the plugin will add a comment to the work package when the pull request is opened, closed, merged or reopened.

If you forget to add the work package URL when creating the pull request, you can edit its description and add the URL, but this doesn't automatically add a comment to the work package (GitHub unfortunately doesn't notify us for this event). To nevertheless add a link between the pull request and the work package, you can add the work package URL in a pull request comment. The plugin then adds a comment to the work package.

We plan to integrate better with GitHub (e.g. show GitHub repository content within OpenProject, comment/merge pull requests from within OpenProject etc.).
To make that happen we happily integrate your pull requests :)

## Requirements

* Same OpenProject version as this plugin.
* The [`openproject-webhooks`](https://github.com/finnlabs/openproject-webhooks) plugin
* Repository management rights on the GitHub repositories you want to integrate

## Installation

This is an OpenProject plugin, thus we follow the usual OpenProject plugin installation mechanism.
Because this plugin depends on the [`openproject-webhooks`](https://github.com/finnlabs/openproject-webhooks) plugin, we also install that plugin.

### Plugin Installation

Edit the `Gemfile.plugins` file in your openproject-installation directory to contain the following lines:

```ruby
gem "openproject-webhooks", :git => 'https://github.com/finnlabs/openproject-webhooks.git', :branch => 'stable'
gem "openproject-github_integration", :git => 'https://github.com/finnlabs/openproject-github_integration.git', :branch => 'stable'
```

Then update your bundle with:

    bundle install

and restart the OpenProject server.

### OpenProject configuration

To enable GitHub integration we need an OpenProject API key of a user with sufficient rights on the projects which shall be synchronized.
Any user will work, but we recommend to create a special 'GitHub' user in your OpenProject installation for that task.

**Note:** Double check that the user whose API key you use has sufficient rights on the projects which shall be synced with GitHub. You can e.g. create a 'GitHub' role with 'Add notes' (Work package tracking) permission, assign the user to this role and add the user in this role to all Projects where you want the user to comment on work packages.

### GitHub configuration

Visit the settings page of the GitHub repository you want to integrate.
Go to the "Webhooks & Services" page.

Within the "Webhooks" section you can create a new webhook with the "Add webhook" button in the top-right corner.

The **Payload URL** is `<the url of your openproject instance>/webhooks/github?key=<API key of the OpenProject user>`.

For **Payload version** select `application/vnd.github.v3+json` (not `...+form`!). If you see GitHub reporting a 403 error for the ping request later, make sure to select the correct one here.

Then select the events which GitHub will send to your OpenProject installation.
We currently only need `Pull Request` and `Issue Comment`, but its also ok to select the *Send me everything* option.

## Contact

OpenProject is supported by its community members, both companies and individuals.

Please find ways to contact us on the OpenProject [support page](https://www.openproject.org/help).

## Contributing

This OpenProject plugin is an open source project and we encourage you to help us out. We'd be happy if you do one of these things:

* Create a new [work package in the GitHub Integration plugin project on openproject.org](https://community.openproject.org/projects/github-integration) if you find a bug or need a feature
* Help out other people on our [forums](https://community.openproject.org/projects/openproject/boards)
* Contribute code via GitHub Pull Requests, see our [contribution page](https://www.openproject.org/open-source/code-contributions/) for more information

## Community

OpenProject is driven by an active group of open source enthusiasts: software engineers, project managers, creatives, and consultants. OpenProject is supported by companies as well as individuals. We share the vision to build great open source project collaboration software.
The [OpenProject Foundation (OPF)](https://www.openproject.org/open-source/) will give official guidance to the project and the community and oversees contributions and decisions.

## Repository

This repository contains two main branches:

* `dev`: The main development branch. We try to keep it stable in the sense of all tests are passing, but we don't recommend it for production systems.
* `stable`: Contains the latest stable release that we recommend for production use. Use this if you always want the latest version of this plugin.

## License

Copyright (C) 2014 the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See [doc/COPYRIGHT.md](doc/COPYRIGHT.md) for details.
