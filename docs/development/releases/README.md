# Releases

This page summarizes all relevant information about releases.

## Distribution

OpenProject is distributed by [various means](../../installation-and-operations/installation/). Manual installation based on the code in GitHub is possible but not supported.

## Release notes

You can find the release notes for major stable releases [here](../../release-notes/).

## Versioning and tags

### General considerations

* See the [Roadmap](https://community.openproject.com/projects/openproject/roadmap) for the overview of the current stable release version and upcoming stable releases
* Releases are defined by a version (number) which exists as tags on predefined development trees (see the branches on [github](https://github.com/opf/openproject/releases)).

### Semantic versioning

* OpenProject follows the idea of [Semantic Versioning](https://semver.org/).
* Therefore the version is a composition of three digits in the format of e.g. 0.1.1 and can be summarised as followed:
  * MAJOR version when you make incompatible API changes,
  * MINOR version when you add functionality in a backwards-compatible manner, and
  * PATCH version when you make backwards-compatible bug fixes.

Since the Stable Release 3.0.8 this idea only applies by considering the OpenProject core and all plugins maintained by the OpenProject Foundation as one piece of software.

### Branches and tags on Github

The stable/X branch with the highest number is the currently supported stable release. Its commits are tagged (e.g. v12.5.8) to pinpoint individual releases.

During the development of upcoming releases, the `release/X.Y` branches are used. Those branches are created of the main development branch `dev` when preparing for a release. A release branch includes all patch level releases.

## Change history

* All changes made to the OpenProject software are documented via work packages. The [Roadmap view](https://community.openproject.com/projects/openproject/roadmap) gives a corresponding overview.
* A release is also summarized in the [release notes](../../release-notes/)

## Support of releases

* For the community edition only the current stable release is maintained. The [Enterprise on-premises](https://www.openproject.org/enterprise-edition) provides extended maintenance.
* We recommended to update to a new stable release as soon as possible to have a supported version installed.
