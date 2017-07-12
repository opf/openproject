# Develop OpenProject

We are pleased that you are thinking about contributing to OpenProject! This guide details how to contribute to OpenProject in a way that is efficient and fun for everyone.

## Get in touch

Please get in touch with us using our [develompment forum](https://community.openproject.com/projects/openproject/boards/7) or send us an email to info@openproject.org.

## Issue tracking and coordination

We eat our own ice cream so we use OpenProject for roadmap planning and team collaboration. Please have a look at the following pages:

- [Development timeline](https://community.openproject.com/projects/openproject/timelines/36)
- [Product roadmap and release planning](https://community.openproject.com/projects/openproject/roadmap)
- [Wish list](https://community.openproject.com/versions/26)
- [Bug backlog](https://community.openproject.com/versions/136)
- [Report a bug](https://www.openproject.org/development/report-a-bug/)
- [Submit a feature idea](https://www.openproject.org/development/submit-feature-idea/)


## Branching model

The main development branch for upcoming releases is `dev`.
If in doubt, create your pull request against `dev`.
All new features, gem updates and bugfixes for the upcoming release should go into the `dev` branch.


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
If you are working on a specific work package from the [list](https://community.openproject.com/projects/openproject/work_packages),
you may include a link to that work package in the description, so we can track your work.

The core contributor team will then review your pull request according to our [code review guideline](https://www.openproject.org/open-source/development-free-project-management-software/code-review-guideliness/).
Please note that you can add commits after the pull request has been created by pushing
to the branch in your fork.

## Translations

If you want to contribute to the localization of OpenProject and its
plugins you can do so on [Crowdin](https://crowdin.com/projects/opf).
Once a day we fetch those locales and upload them to GitHub.

More on this topic can be found in our [blog post](https://www.openproject.org/help-translate-openproject-into-your-language/).


## Testing

Please add tests to your code to verify functionality, especially if it is a new feature.

Pull requests will be verified by TravisCI as well,
but please run them locally as well and make sure they are green before creating your pull request.
We have a lot of pull requests coming in and it takes some time to run the complete suite for each one.

If you push to your branch in quick succession, please consider stopping the associated Travis builds, as Travis will run for each commit. This is especially true if you force push to the branch.

Please also use `[ci skip]` in your commit message to suppress builds which are not necessary
(e.g. after fixing a typo in the `README`).


## Bugs and hotfixes

Bugfixes for one of the actively supported versions of OpenProject should be issued against the respective branch.
A fix for the current version (called "Hotfix" and the branch ideally being named `hotfix/XYZ`)
should target `release/*` and a fix for the former version
(called "Backport" and the branch ideally being named `backport/XYZ`)
should target `backport/*`. We will try to merge hotfixes into dev branch
but if that is no trivial task, we might ask you to create another PR for that.

## Inactive pull requests

We want to keep the Pull request list as cleaned up as possible - we will aim close pull requests
after an **inactivity period of 30 days** (no comments, no further pushes)
which are not labelled as `work in progress` by us.

## Security

If you notice a security issue in OpenProject, please send us a gpg encrypted email to security@openproject.org and describe the issue you found. Download our public gpg key [here](https://pgp.mit.edu/pks/lookup?op=get&search=0x7D669C6D47533958).

Please include a description on how to reproduce the issue if possible. Our security team will get your email and will attempt to reproduce and fix the issue as soon as possible.

## Accessibility

For our impaired users please have a look at our [accessibility-checklist](https://www.openproject.org/development/accessibility-checklist/).

## Contributor code of conduct

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

This code of conduct is adapted from the
[Contributor Covenant](http:contributor-covenant.org),
version 1.0.0, available at
[http://contributor-covenant.org/version/1/0/0/](http://contributor-covenant.org/version/1/0/0/)

## Contributors license agreement

Contributors have to sign a CLA before contributing to OpenProject.
The [CLA can be found here](https://www.openproject.org/wp-content/uploads/2015/08/Contributor-License-Agreement.pdf)
and has to be filled out and sent to info@openproject.org.
