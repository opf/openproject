# Release process

This page summarizes all relevant information about the release process.

## Distribution

* The OpenProject software and plugins developed by the OpenProject Foundation itself are maintained on [Github](https://github.com/opf).
* Releases exist as snapshots (tags) of different development trees (branches) at a specific point in time.

**Explanatory note:**

Due to the fact that the OpenProject Foundation provides releases in the form of the source code itself all release types are fully self-contained. This means that a hotfix release for example does not only include parts of the software which are going to be fixed by the hotfix release itself. Instead it includes the latest stable release and the fixes it was built for (i.e. we don't release patches separately).

## Release notes

You can find the release notes for major stable releases [here](https://www.openproject.org/release-notes/).

## Release cycles

### Stable release

* The OpenProject Foundation releases four Stable Releases per year.
* The Release plan is tracked via the [OpenProject community](https://community.openproject.com/projects/openproject/).

### Hotfix release

* Hotfix releases follow no predefined release plan in the release process.
* As soon as a bug is declared to be critical and there has to be an emergency update to currently supported stable releases a hotfix release will be prepared. However, the criteria which define a bug to be critical depend on several conditions which make it almost impossible to give a clear definition of what constitutes a critical bug.

## Versioning and tags

### General considerations

* See the [Roadmap](https://community.openproject.com/projects/openproject/roadmap) for the overview of the current stable release version and  upcoming stable releases
* Releases are defined by a version (number) which exists as tags on predefined development trees (see the branches on [github](https://github.com/opf/openproject/releases)).
* All plugins maintained by the OpenProject Foundation have the same release cycle and the same version as the OpenProject software itself (typically called OpenProject core or just core).
* The version of plugins indicate the compatibility with the core.
* The OpenProject Foundation will ensure this via continuous integration testing.

### Semantic versioning

* OpenProject follows the idea of [Semantic Versioning](http://semver.org/).
* Therefore the version is a composition of three digits in the format of e.g. 0.1.1 and can be summarised as followed:
  * MAJOR version when you make incompatible API changes,
  * MINOR version when you add functionality in a backwards-compatible manner, and
  * PATCH version when you make backwards-compatible bug fixes.

Since the Stable Release 3.0.8 this idea only applies by considering the OpenProject core and all plugins maintained by the OpenProject Foundation as one piece of software.

### Side Note: Keeping core and plugin versions in lockstep

* Due to the fact that plugins inherit their version from the core of the OpenProject software and vice versa there are some implications to mention.
* Since this only applies to the versions starting at version 3.0.8 (core) there are plugins which have surpassed this version in the past. The most noticeable is the costs plugin which version was set back from version 5.0.4 to 3.0.8.
* Furthermore it is likely that the version may change for a lot of plugins or the core itself, although the source code of these software parts did not change at all. The reason for that is the described inheritance of versions.

### Branches and tags on Github

* There are two important branches in regard to the release process:
  * dev: development of future stable releases
  * release/X.Y: currently supported stable release
* Tags on these two branches refer either to sprint releases (dev) or stable respectively hotfix releases (release/X.Y).

## Change history

* All changes made to the OpenProject software are documented via work packages. The [Roadmap view](https://community.openproject.com/projects/openproject/roadmap) gives a corresponding overview.
* To prevent inconsistencies and avoid redundant work there is there is no additional change log in the source code.

## Support of releases

* For the community edition only the current stable releases are maintained. The [Enterprise Edition](https://www.openproject.org/enterprise-edition) provides extended maintenance.
* We recommended to update to a new stable release as soon as possible to have a supported version installed.
