OpenProject is an open source project and we encourage you to help us out. For contributing to OpenProject, please read the following guidelines:

## Development flow
For contributing source code, please follow the Git Workflow below:

- Fork OpenProject on GitHub
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

- Create a pull request (PR) against a branch of of the <opf/openproject> repository, containing a ***clear description*** of what the pull request attempts to change and/or fix. 

We will then review your PR. Please note that you can add commits after the PR has been created by pushing to the branch in your fork.

## Important notes

- Please add tests to your code to verify functionality, especially if it is a new feature. Please also run these tests locally.
- Please create pull requests against the current `dev` branch. Hotfixes and Bugfixes should be created against the appropiate `release/*` branch.
- We want to keep the Pull request list as cleaned up as possible - we will aim close pull requests after an **inactivity period of 72 hours** (no comments, no further pushes) which are not labelled as `work in progress` by us.
- We use OpenProject for development coordination - please have a look at [the work packages list](https://community.openproject.org/projects/openproject/work_packages) for upcoming features and reported bugs.
