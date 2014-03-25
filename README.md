# OpenProject Github Integration Plugin

**Warning**: This is work in progress.

`openproject-github_integration` is an OpenProject plugin, which aims to integrate github code repositories and a pull request workflow with OpenProject.

Currently we support pasting WorkPackage urls into a GitHub pull request.
When the pull request is opened/closed this plugin writes a comment in
all mentioned WorkPackages.

We plan to integrate better with GitHub (e.g. show GitHub repository content within OpenProject, comment/merge pull requests from within OpenProject etc.).
To make that happen we happily integrate your pull requests :)

## Requirements

* OpenProject version **3.1.0 or higher** ( or a current installation from the `dev` branch)
* [`openproject-webhooks`](https://github.com/finnlabs/openproject-webhooks)
* Repository management rights on the GitHub repositories you want to integrate

## Installation and Setup:

This is an OpenProject plugin, thus we follow the usual OpenProject plugin installation mechanism.
Because we depend on the [`openproject-webhooks`](https://github.com/finnlabs/openproject-webhooks) plugin, we also install that plugin.

### Plugin Installation

Edit the `Gemfile.plugins` file in your openproject-installation directory to contain the following lines:

<pre>
gem "openproject-webhooks", :git => 'https://github.com/finnlabs/openproject-github_integration.git', :branch => 'stable'
gem "openproject-github_integration", :git => 'https://github.com/finnlabs/openproject-github_integration.git', :branch => 'stable'
</pre>

Then update your bundle with:

<pre>
bundle install
</pre>

and restart the OpenProject server.

### OpenProject configuration

To enable GitHub integration we need an OpenProject API key of a user with sufficient rights on the projects which shall be synchronized.
Any user will work, but we recommend to create a special 'GitHub' user in your OpenProject installation for that task.

**Note:** Double check that the user whose API key you use has sufficient rights on the projects which shall be synced with GitHub (e.g. the user is a member if those projects and has the 'Create WorkPackage Comments' right).

### GitHub configuration

Visit the settings page of the GitHub repository you want to integrate.
Go to the "Webhooks & Services" page.

Within the "Webhooks" section you can create a new webhook with the "Add webhook" button in the top-right corner.

The **Payload URL** is `<the url of your openproject instance>/webhooks/github?key=<API key of the OpenProject user>`.

For **Payload version** select `application/vnd.github.v3+json` (not `...+form`!).

Then select the events which GitHub will send to your OpenProject installation.
We currently only need `Pull Request` and `Issue Comment`, but you are save to select the *Send me everything* option.


## Get in Contact

OpenProject is supported by its community members, both companies as well as individuals. There are different possibilities of getting help:
* OpenProject [support page](https://www.openproject.org/projects/openproject/wiki/Support)
* E-Mail Support - info@openproject.org

## Start Collaborating

Join the OpenProject community and start collaborating. We envision building a platform to share ideas, contributions, and discussions around OpenProject and project collaboration. Each commitment is noteworthy as it helps to improve the software and the project.
More details will be added on the OpenProject Community [contribution page](https://www.openproject.org/projects/openproject/wiki/Contribution).

In case you find a bug or need a feature, please report at https://www.openproject.org/projects/github-integration/work_packages

## License

Copyright (C) 2013 the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md for details.
