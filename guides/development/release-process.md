# Release Process

The OpenProject world distinguishes in its release process three kinds of releases: stable, hotfix and and a sprint release. This page summarizes all relevant information about the release process.

## Distribution

* The OpenProject software and plugins developed by the OpenProject Foundation itself are maintained on [Github](https://github.com/opf).
* Releases exist as snapshots (tags) of different development trees (branches) at a specific point in time.

**Explanatory note:**

Due to the fact that the OpenProject Foundation provides releases in the form of the source code itself all release types are fully self-contained. This means that a hotfix release for example does not only include parts of the software which are going to be fixed by the hotfix release itself. Instead it includes the latest stable release and the fixes it was built for (i.e. we don't release patches separately).

## Release Notes

You can find the release notes for major stable releases [here](https://www.openproject.org/open-source/release-notes/).

## Release cycles

### Stable Release

* The OpenProject Foundation releases four Stable Releases per year.
* The Release plan is tracked via the [project timeline](https://community.openproject.com/projects/openproject/timelines/36).

### Hotfix Release

* Hotfix releases follow no predefined release plan in the release process.
* News article will be used to inform the community about hotfix releases.
* As soon as a bug is declared to be critical and there has to be an emergency update to currently supported stable releases a hotfix release will be prepared. However, the criteria which define a bug to be critical depend on several conditions which make it almost impossible to give a clear definition of what constitutes a critical bug.
 
## Versioning and Tags

### General considerations

* See the [Roadmap](https://community.openproject.com/projects/openproject/roadmap) for the overview of the current stable release version and   upcoming stable releases
* The concrete version of the upcoming stable release is determined as part of the quarterly mid term planning by the OpenProject Foundation.
* Releases are defined by a version (number) which exists as tags on predefined development trees (see the branches on [github](https://github.com/opf/openproject/releases)).
* All plugins maintained by the OpenProject Foundation have the same release cycle and the same version as the OpenProject software itself (typically called OpenProject core or just core).
* The version of plugins indicate the compatibility with the core.
* The OpenProject Foundation will ensure this via continuous integration testing.

### Versioning in Detail

* OpenProject follows the idea of [Semantic Versioning](http://semver.org/).
* Therefore the version is a composition of three digits in the format of e.g. 0.1.1 and can be summarised as followed:
  * MAJOR version when you make incompatible API changes,
  * MINOR version when you add functionality in a backwards-compatible manner, and
  * PATCH version when you make backwards-compatible bug fixes.

Since the Stable Release 3.0.8 this idea only applies by considering the OpenProject core and all plugins maintained by the OpenProject Foundation as one piece of software.

### Side Note: Keeping Core and Plugin Versions in lockstep

* Due to the fact that plugins inherit their version from the core of the OpenProject software and vice versa there are some implications to mention.
* Since this only applies to the versions starting at version 3.0.8 (core) there are plugins which have surpassed this version in the past. The most noticeable is the costs plugin which version was set back from version 5.0.4 to 3.0.8.
* Furthermore it is likely that the version may change for a lot of plugins or the core itself, although the source code of these software parts did not change at all. The reason for that is the described inheritance of versions.
 
### What is the benefit then?

* At the current state the OpenProject software architecture lacks on a defined interface for plugins. Therefore a lot of plugins overwrite the OpenProject core in an undesirable manner.
* With more and more plugins available this is a problem because one plugin can break the whole software, even those parts, which the plugin itself is not responsible for.
* This is a huge problem when it comes to tests because that means at least in theory all the combination (versions) of plugins used have to be tested. Furthermore combinations that work as expected have to be tracked and this documentation has to be updated whenever new versions of a plugins are developed. This is a very serious issue.
* To address these two issues it was decided to keep the version of the core within the release process in lockstep with the plugins. By doing so the testing of the OpenProject core with different combinations of plugins can be reduced to a minimum. Per definition the last stable core has to be working with the last stable plugins all sharing the same version. A documentation of which plugin and core version works together becomes obsolete because it is defined by convention.
* This method seems to be the most clear and most straight forward approach for now and the near future. It also has the advantage that plugin development and core development have to be more aligned than ever before.
* The OpenProject Foundation is aware that this solution should only be temporary and therefore should be replaced as soon as the described architectural restrictions of handling plugins are resolved.

### Branches and Tags on Github

* There are two important branches in regard to the release process:
  * dev: development of future stable releases
  * release/X.Y: currently supported stable release
* Tags on these two branches refer either to sprint releases (dev) or stable respectively hotfix releases (release/X.Y).

## History of Changes

* As of OpenProject Stable Release 3.0.8 all changes made to the OpenProject software are documented via work packages in the [OpenProject project](https://community.openproject.com/projects/openproject).
* The [Roadmap view](https://community.openproject.com/projects/openproject/roadmap) gives a corresponding overview.
* To prevent inconsistencies and avoid redundant work there is there is no additional change log in the source code.

## Support of Releases

* The last two stable releases are maintained.
* That is why it is strongly recommended to update to a new stable release as soon as possible to have a supported version installed. Time available for doing the update is defined by the release cycle (see above).
