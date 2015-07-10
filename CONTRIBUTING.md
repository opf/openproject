OpenProject is an open source project and we encourage you to help us out.
For contributing to OpenProject, please read the following guidelines.

*Please also note that these rules should be acknowledged by everyone,
but repository contributors might occasionally deviate from them for practical purposes,
e.g. not fork the repo, but have a branch on the main repository.
This should however stay an exception.*

## Contributors License Agreement

External contributors have to sign a CLA before contributing to OpenProject.
The [CLA can be found here](https://www.openproject.org/wp-content/uploads/2014/09/OPF-Contributor-License-Agreement_v.2.pdf)
and has to be filled out and sent to cla@openproject.org.
Additionally, a GPG signature has to be provided.

## Development flow

For contributing source code, please follow the git workflow below:

- **Fork** OpenProject on GitHub
- Clone your fork to your development machine:

```
git clone git@github.com/<username>/openproject
```

- Optional: Add the original OpenProject repository as a remote, so you can fetch changes:

```
git remote add upstream git@github.com:opf/openproject
```

- Make sure you're on the right branch. The main development branch is `dev`:

```
git checkout dev
```

- Create a feature branch:

```
git checkout -b feature/<short description of your feature>
```

- Make your changes, then push the branch into your ***own*** repository:

```
git push origin <your feature branch>
```

- Create a pull request against a branch of of the <opf/openproject> repository, containing a ***clear description*** of what the pull request attempts to change and/or fix.

If your pull request **does not contain a description** for what it does and what it's intentions are,
we will reject it.
If you are working on a specific work package from the [list](https://community.openproject.org/projects/openproject/work_packages?query_props=%7B%22c%22:%5B%22type%22,%22status%22,%22subject%22,%22assigned_to%22%5D,%22t%22:%22parent:desc%22,%22f%22:%5B%7B%22n%22:%22status_id%22,%22o%22:%22!%22,%22t%22:%22list_status%22,%22v%22:%5B%2217%22,%2223%22,%223%22,%2214%22,%226%22%5D%7D%5D,%22pa%22:1,%22pp%22:20%7D),
you may include a link to that work package in the description, so we can track your work.

We will then review your pull request.
Please note that you can add commits after the pull request has been created by pushing
to the branch in your fork.

## Translations

Beginning with OpenProject 4.2.0 the OpenProject core only holds the
english locales and all other locales are stored in
OpenProject-Translations. But since this plugin is hardwired in the
Gemfile, german and other locales are available again.

If you want to contribute to the localization of OpenProject and its
plugins you can do so on [Crowdin](https://crowdin.com/projects/opf).
Once a day we will fetch those locales and upload them to GitHub.

More on this topic can be found [in our blog](https://www.openproject.org/2015/07/10/help-translate-openproject-into-your-language/).

## Important notes

To ensure a smooth workflow for everyone, please take note of the following:

### Testing

Please add tests to your code to verify functionality, especially if it is a new feature.

Pull requests will be verified by TravisCI as well,
but please run them locally as well and make sure they are green before creating your pull request.
We have a lot of pull requests coming in and it takes some time to run the complete suite for each one.

### Branching model

The main development branch for upcoming releases is `dev`.
If in doubt, create your pull request against `dev`.
All new features, gem updates and bugfixes for the upcoming release should go into the `dev` branch.

#### Bugs and hotfixes

Bugfixes for one of the actively supported versions of OpenProject
should be issued against the respective branch.
A fix for the current version (called "Hotfix" and the branch ideally being named `hotfix/XYZ`)
should target `release/*` and a fix for the former version
(called "Backport" and the branch ideally being named `backport/XYZ`)
should target `backport/*`. We will try to merge hotfixes into dev branch
but if that is no trivial task, we might ask you to create another PR for that.

#### Travis CI

If you push to your branch in quick sucession, please consider stopping the associated Travis builds,
as Travis will run for each commit. This is especially true if you force push to the branch.

Please also use `[ci skip]` in your commit message to suppress builds which are not necessary
(e.g. after fixing a typo in the `README`).

### Inactive pull requests

We want to keep the Pull request list as cleaned up as possible - we will aim close pull requests
after an **inactivity period of 72 hours** (no comments, no further pushes)
which are not labelled as `work in progress` by us.

### Issue tracking and coordination

We use OpenProject for development coordination - please have a look at
[the work packages list](https://community.openproject.org/projects/openproject/work_packages?query_props=%7B%22c%22:%5B%22type%22,%22status%22,%22subject%22,%22assigned_to%22%5D,%22t%22:%22parent:desc%22,%22f%22:%5B%7B%22n%22:%22status_id%22,%22o%22:%22!%22,%22t%22:%22list_status%22,%22v%22:%5B%2217%22,%2223%22,%223%22,%2214%22,%226%22%5D%7D%5D,%22pa%22:1,%22pp%22:20%7D)
for upcoming features and reported bugs.

### Contributor Code of Conduct

As contributors and maintainers of this project, we pledge to respect all people
who contribute through reporting issues, posting feature requests,
updating documentation, submitting pull requests or patches, and other activities.

We are committed to making participation in this project a harassment-free experience for everyone,
regardless of level of experience, gender, gender identity and expression, sexual orientation,
disability, personal appearance, body size, race, age, or religion.

Examples of unacceptable behavior by participants include the use of sexual language
or imagery, derogatory comments or personal attacks, trolling, public or private harassment,
insults, or other unprofessional conduct.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits,
code, wiki edits, issues, and other contributions that are not aligned to this Code of Conduct.
Project maintainers who do not follow the Code of Conduct may be removed from the project team.

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported
by opening an issue or contacting one or more of the project maintainers.

This Code of Conduct is adapted from the
[Contributor Covenant](http:contributor-covenant.org),
version 1.0.0, available at
[http://contributor-covenant.org/version/1/0/0/](http://contributor-covenant.org/version/1/0/0/)

### Get in touch

If you want to get in touch with us, there is also a
[Gitter channel](https://gitter.im/opf/openproject) to talk to us directly.
