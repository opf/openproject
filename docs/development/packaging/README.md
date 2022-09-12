---
sidebar_navigation:
  title: Packaging
  priority: 920
---

# Packaging of OpenProject with packager.io

OpenProject relies on [packager.io](https://packager.io) to provide the packaged installation method for the supported distributions.

This guide will provide some insights in how to develop and test integrations with the packager build process. It assumes that you are familiar with the [packager.io building documentation](https://github.com/crohr/pkgr/wiki).

## Continuous integration

The packager.io website observes changes in the repository through webhooks and will automatically triggers builds for these branches:

- `dev`: https://packager.io/gh/opf/openproject
- `release/*` (e.g.,) https://packager.io/gh/opf/openproject/refs/release/12.2
- `stable/*` (e.g.,) https://packager.io/gh/opf/openproject/refs/stable/12
- `packaging/*`

To see the status of a build, simply follow one of the links and choose a distribution whose logs you want to look at.

## Testing a packaging-related bug fix

If you need a package of your changes before they are being merged, simply create a branch with the prefix `packaging/` to allow it being build.

Then, trigger its builds using this URL: `https://packager.io/gh/opf/openproject/refs/BRANCH-NAME`. For example: https://packager.io/gh/opf/openproject/refs/packaging/custom-plugin-frozen

If you're pushing multiple commits and want faster turnover times, reduce the number of available distributions in the `.pkgr.yml` to only the ones you want to test here: https://github.com/opf/openproject/blob/dev/.pkgr.yml

**Important:** Remember to remove those changes before merging!
