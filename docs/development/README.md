# Develop OpenProject

We are pleased that you are thinking about contributing to OpenProject! This guide details how to contribute to OpenProject.

## Get in touch

Please get in touch with us using our [develompment forum](https://community.openproject.com/projects/openproject/forums/7) or send us an email to info@openproject.org.

## Issue tracking and coordination

We eat our own ice cream so we use OpenProject for roadmap planning and team collaboration. Please have a look at the following pages:

- [Development roadmap](https://community.openproject.com/projects/openproject/work_packages?query_id=1993)
- [Wish list](https://community.openproject.com/versions/26)
- [Bug backlog](https://community.openproject.com/versions/136)
- [Reporting a bug](https://www.openproject.org/development/report-a-bug/)
- [Submit a feature idea](https://www.openproject.org/development/submit-feature-idea/)

## Development Environment

Take a look at the bottom under Additional resources to see how to setup your development environment.

## Branching model

The main development branch for upcoming releases is `dev`. If in doubt, create your pull request against `dev`. All new features, gem updates and bugfixes for the upcoming release should go into the `dev` branch.

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

- Make your changes, then push the branch into your **own** repository:

```
git push origin <your feature branch>
```

- Create a pull request against a branch of of the <opf/openproject> repository, containing a **clear description** of what the pull request attempts to change and/or fix.

If your pull request **does not contain a description** for what it does and what it's intentions are, we will reject it. If you are working on a specific work package from the [list](https://community.openproject.com/projects/openproject/work_packages), please include a link to that work package in the description, so we can track your work.

The core contributor team will then review your pull request according to our [code review guideline](https://www.openproject.org/open-source/development-free-project-management-software/code-review-guideliness/). Please note that you can add commits after the pull request has been created by pushing to the branch in your fork.

## Translations

If you want to contribute to the localization of OpenProject and its plugins you can do so on the [Crowdin OpenProject page](https://crowdin.com/project/openproject). Once a day we fetch those locales and automatically them to GitHub. Contributing there will ensure your language will be up to date for the next release!

More on this topic can be found in our [blog post](https://www.openproject.org/help-translate-openproject-into-your-language/).

## Testing

Please add tests to your code to verify functionality, especially if it is a new feature.

Pull requests will be verified by TravisCI as well, but please run them locally as well and make sure they are green before creating your pull request. We have a lot of pull requests coming in and it takes some time to run the complete suite for each one.

If you push to your branch in quick succession, please consider stopping the associated Travis builds, as Travis will run for each commit. This is especially true if you force push to the branch.

Please also use `[ci skip]` in your commit message to suppress builds which are not necessary (e.g. after fixing a typo in the `README`).

## Bugs and hotfixes

Bugfixes for one of the actively supported versions of OpenProject should be issued against the respective branch. A fix for the current version (called "Hotfix" and the branch ideally being named `hotfix/XYZ`) should target `release/*` and a fix for the former version (called "Backport" and the branch ideally being named `backport/XYZ`) should target `backport/*`. We will try to merge hotfixes into dev branch but if that is no trivial task, we might ask you to create another PR for that.

## Inactive pull requests

We want to keep the Pull request list as cleaned up as possible - we will aim close pull requests after an **inactivity period of 30 days** (no comments, no further pushes) which are not labelled as `work in progress` by us.

## Security

If you notice a security issue in OpenProject, please send us a gpg encrypted email to security@openproject.com and describe the issue you found. Download our public gpg key BDCF E01E DE84 EA19 9AE1 72CE 7D66 9C6D 4753 3958 [here](https://keys.openpgp.org/vks/v1/by-fingerprint/BDCFE01EDE84EA199AE172CE7D669C6D47533958).

Please include a description on how to reproduce the issue if possible. Our security team will get your email and will attempt to reproduce and fix the issue as soon as possible.

## Contributor code of conduct

As contributors and maintainers of this project, we pledge to respect all people who contribute through reporting issues, posting feature requests, updating documentation, submitting pull requests or patches, and other activities.

We are committed to making participation in this project a harassment-free experience for everyone, regardless of level of experience, gender, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, age, or religion.

Examples of unacceptable behavior by participants include the use of sexual language or imagery, derogatory comments or personal attacks, trolling, public or private harassment, insults, or other unprofessional conduct.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned to this Code of Conduct. Project maintainers who do not follow the Code of Conduct may be removed from the project team.

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by opening an issue or contacting one or more of the project maintainers.

This code of conduct is adapted from the [Contributor Covenant](http://contributor-covenant.org/), version 1.0.0, available at http://contributor-covenant.org/version/1/0/0/



## OpenProject Contributor License Agreement (CLA)

If you want to contribute to OpenProject, please make sure to accept our Contributor License Agreement first. The contributor license agreement documents the rights granted by contributors to OpenProject.

[Read and accept the Contributor License Agreement here.](http://openproject.org/contributor-license-agreement/)

# Additional resources


* [Development environment for Ubuntu 18.04](development-environment-ubuntu)
* [Development environment for Mac OS X](development-environment-osx)
* [Development environment using docker](development-environment-docker)

* [Developing Plugins](create-openproject-plugin)
* [Running Tests](running-tests)
* [API Documentation](/api/)
* [Report a Bug](report-a-bug)
