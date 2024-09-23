---
sidebar_navigation:
  title: Development
  priority: 920
---

# Develop OpenProject

We are pleased that you are thinking about contributing to OpenProject! This guide details how to contribute to OpenProject.

## Get in touch

Please get in touch with us using our [development forum](https://community.openproject.org/projects/openproject/forums/7) or send us an email to info@openproject.org.

## Issue tracking and coordination

We eat our own ice cream so we use OpenProject for roadmap planning and team collaboration. Please have a look at the following pages:

- [Development roadmap](https://community.openproject.org/projects/openproject/roadmap)

- [Wish list](https://community.openproject.org/projects/openproject/work_packages?query_id=180)

- [Bug backlog](https://community.openproject.org/projects/openproject/work_packages?query_id=491)

- [Reporting a bug](report-a-bug)

- [Submit a feature idea](submit-feature-idea)

## Development Environment

Take a look at the bottom under Additional resources to see how to setup your development environment.

## Highlighting Development Environment

To make it easier to distinguish a development instance, it is using a tinted website icon and modified app header.

This behavior can be disabled by setting an environment variable `OPENPROJECT_DEVELOPMENT_HIGHLIGHT_ENABLED=false` (see also [documentation on configuration](../installation-and-operations/configuration/)).

## Branching model and development flow

Please see this separate guide for the [git branching model and core development](git-workflow/).

## Development concepts

We prepared a set of documentation concepts for an introduction into various backend and frontend related topics of OpenProject. Please see the [concepts main page](concepts/) for more.

## Translations

If you want to contribute to the localization of OpenProject and its plugins you can do so on the [Crowdin OpenProject page](https://crowdin.com/project/openproject). Once a day we fetch those locales and automatically upload them to GitHub. Contributing there will ensure your language will be up to date for the next release!

More on this topic can be found in our [blog post](https://www.openproject.org/blog/help-translate-openproject-into-your-language/).

## Packaging process

Please see this separate guide for the [process of building packages of OpenProject](packaging/).

## Testing

Please add tests to your code to verify functionality, especially if it is a new feature.

Pull requests will be verified by TravisCI as well, but please run them locally as well and make sure they are green before creating your pull request. We have a lot of pull requests coming in and it takes some time to run the complete suite for each one.

If you push to your branch in quick succession, please consider stopping the associated Travis builds, as Travis will run for each commit. This is especially true if you force push to the branch.

Please also use `[ci skip]` in your commit message to suppress builds which are not necessary (e.g. after fixing a typo in the `README`).

## Inactive pull requests

We want to keep the Pull request list as cleaned up as possible - we will aim close pull requests after an **inactivity period of 30 days** (no comments, no further pushes) which are not labeled as `work in progress` by us.

## Security

If you notice a security issue in OpenProject, please send us a GPG encrypted email to security@openproject.com and describe the issue you found. Download our public GPG key BDCF E01E DE84 EA19 9AE1 72CE 7D66 9C6D 4753 3958 [here](https://keys.openpgp.org/vks/v1/by-fingerprint/BDCFE01EDE84EA199AE172CE7D669C6D47533958).

Please include a description on how to reproduce the issue if possible. Our security team will get your email and will attempt to reproduce and fix the issue as soon as possible.

## Contributor code of conduct

As contributors and maintainers of this project, we pledge to respect all people who contribute through reporting issues, posting feature requests, updating documentation, submitting pull requests or patches, and other activities.

We are committed to making participation in this project a harassment-free experience for everyone, regardless of level of experience, gender, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, age, or religion.

Examples of unacceptable behavior by participants include the use of sexual language or imagery, derogatory comments or personal attacks, trolling, public or private harassment, insults, or other unprofessional conduct.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned to this Code of Conduct. Project maintainers who do not follow the Code of Conduct may be removed from the project team.

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by opening an issue or contacting one or more of the project maintainers.

This code of conduct is adapted from the [Contributor Covenant](https://www.contributor-covenant.org/), version 1.0.0, available at [contributor-covenant.org/version/1/0/0/](https://www.contributor-covenant.org/version/1/0/0/)

## OpenProject Contributor License Agreement (CLA)

If you want to contribute to OpenProject, please make sure to accept our Contributor License Agreement first. The contributor license agreement documents the rights granted by contributors to OpenProject.

[Read and accept the Contributor License Agreement here.](https://www.openproject.org/legal/contributor-license-agreement/)

## Additional resources

* [Development environment](development-environment)
* [Developing Plugins](create-openproject-plugin)
* [Running Tests](running-tests)
* [API Documentation](../api)
* [Report a Bug](report-a-bug)
