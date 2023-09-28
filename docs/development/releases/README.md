# Releases

This page summarizes all relevant information about releases.

## Current release

The [release notes](../../release-notes/) provide a list of all the releases including the current stable one.

Administrators can identify their currently deployed version of OpenProject in the [Administration information page of their installation](../../system-admin-guide/information).

## Upcoming releases

See the [Roadmap](https://community.openproject.com/projects/openproject/roadmap) for the overview of the upcoming stable releases.

## Versioning

OpenProject follows [Semantic Versioning](https://semver.org/).
Therefore, the version is a composition of three digits in the format of e.g. 0.1.1 and can be summarised as followed:
  * MAJOR version when you make incompatible API changes,
  * MINOR version when you add functionality in a backwards-compatible manner, and
  * PATCH version when you make backwards-compatible bug fixes.

Please note that OpenProject considers the following to be non breaking changes which do not lead to a new major version:
* Database schema changes
* Updates on depended upon libraries packaged with the distributions of OpenProject (e.g. Ruby, Rails, etc.)

Changes to those can thus happen also in minor or patch releases.

On the other hand, changes to the following are considered breaking changes and thus lead to a new major version.
* Changes to the minimum version of supported operating systems.
* Changes to the minimum version of the supported database system (PostgreSQL).

This list is not conclusive but rather serves to highlight the difference to the previous list of non breaking changes.

## Support of releases

For the community edition, only the current stable release is maintained. The [Enterprise on-premises](https://www.openproject.org/enterprise-edition) provides extended maintenance.

We recommended to update to a new stable release as soon as possible to have a supported version installed. To that end, OpenProject will show an information banner to administrators in case a new stable release is available.


## Change history

All changes made to the OpenProject software are documented via work packages bundled by the version. The [Roadmap view](https://community.openproject.com/projects/openproject/roadmap) gives a corresponding overview. A release is also summarized in the [release notes](../../release-notes/).

## Distribution

OpenProject is distributed in [various formats](../../installation-and-operations/installation/). Manual installation based on the code in GitHub is possible but not supported.

## Versions in the codebase

The version is represented as [tags](../git-workflow#tagging) and [branches](../git-workflow#branching-model) in the repository. The version is also manifested in the [version.rb](https://github.com/opf/openproject/blob/dev/lib/open_project/version.rb).
