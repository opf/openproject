OpenProject is an open source project and we encourage you to help us out. For contributing to OpenProject, please read the following guidelines. 

*Please also note that these rules should be acknowledged by everyone, but repository contributors might occasionally deviate from them for practical purposes, e.g. not fork the repo, but have a branch on the main repository.*

## Contributors License Agreement

External contributors have to sign a CLA before contributing to OpenProject.
The [CLA can be found here](https://www.openproject.org/wp-content/uploads/2014/09/OPF-Contributor-License-Agreement_v.2.pdf) and has to be filled out and sent to cla@openproject.org. Additionally, a GPG signature has to be provided.

## Development flow

For contributing source code, please follow the Git Workflow below:

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

If your pull request **does not contain a description** for what it does and what it's intentions are, we will reject it. If you are working on a specific work package from the [list](https://community.openproject.org/projects/openproject/work_packages?query_props=%7B%22c%22:%5B%22type%22,%22status%22,%22subject%22,%22assigned_to%22%5D,%22t%22:%22parent:desc%22,%22f%22:%5B%7B%22n%22:%22status_id%22,%22o%22:%22!%22,%22t%22:%22list_status%22,%22v%22:%5B%2217%22,%2223%22,%223%22,%2214%22,%226%22%5D%7D%5D,%22pa%22:1,%22pp%22:20%7D), you may include a link to that work package in the description, so we can track your work.

We will then review your pull request. Please note that you can add commits after the pull request has been created by pushing to the branch in your fork.

## Important notes

To ensure a smooth workflow for, please take note of the following:

### Testing

Please add tests to your code to verify functionality, especially if it is a new feature.

Pull requests will be verified by TravisCI as well, but please run them locally as well. We have a lot of pull requests coming in and it takes some time to run the complete suite for each one.

### Code style guidelines

We use [RuboCop](https://github.com/bbatsov/rubocop) to verify our code style for Ruby. A [RuboCop configuration](https://github.com/opf/openproject/blob/dev/.rubocop.yml) is included in the repository for your convenience. 

Individual files can also be autocorrected with 

```
rubcocop -a ./path/to/file
```

JavaScript style for the frontend can be verified via a `gulp` task in the `frontend` folder:

```
gulp lint
```

Additionally, we use HoundCI to verifiy the styles for Ruby, as well as for JavaScript. We will reject pull requests which do not meet the code style requirements.

The style guide applies **to lines you touch**. you do **not** have to correct a file completely if you only touch a single line for a bugfix. When in doubt, the matter will be discussed in the pull request.

### Branching model

The main development branch for upcoming releases is `dev`. For identifying the branch to create a pull request against, please refer to these rules:

- If in doubt, create your pull request against `dev`. All new features, gem updates and bugfixes for the upcoming release should go into the `dev` branch.
- Hotfixes should be created against the appropiate `release/*` branch. Backports for fixes also go against their specific `release/*` branch.

### Inactive pull requests

We want to keep the Pull request list as cleaned up as possible - we will aim close pull requests after an **inactivity period of 72 hours** (no comments, no further pushes) which are not labelled as `work in progress` by us.

### Issue tracking and coordination

We use OpenProject for development coordination - please have a look at [the work packages list](https://community.openproject.org/projects/openproject/work_packages?query_props=%7B%22c%22:%5B%22type%22,%22status%22,%22subject%22,%22assigned_to%22%5D,%22t%22:%22parent:desc%22,%22f%22:%5B%7B%22n%22:%22status_id%22,%22o%22:%22!%22,%22t%22:%22list_status%22,%22v%22:%5B%2217%22,%2223%22,%223%22,%2214%22,%226%22%5D%7D%5D,%22pa%22:1,%22pp%22:20%7D) for upcoming features and reported bugs.

### Etiquette and communication

Lastly, be nice and respectful to each other. We are working hard to make OpenProject the best project management software there is and we are grateful for each contribution. 

If you want to get in touch with us, there is also a [Gitter channel](https://gitter.im) to talk to us directly.
