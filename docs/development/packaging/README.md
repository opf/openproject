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
- `release/*` (e.g.,) https://packager.io/gh/opf/openproject/refs/release/13.0
- `stable/*` (e.g.,) https://packager.io/gh/opf/openproject/refs/stable/14
- `packaging/*`

To see the status of a build, simply follow one of the links and choose a distribution whose logs you want to look at.

## Debugging an installed packager integration

In some cases, you have an existing packaged installation and would like to debug or change parts of an addon to see if it breaks or works the way you expect it to.

In an installed installations, these are the paths you have to look for:

`/opt/openproject` : location of the repository, all ruby and frontend code. Changing any ruby code will require you to restart the web service with `systemctl restart openproject`

`/usr/share/openproject/installer/addons/` : Location of the addons such as the openproject integration. Changing anything there will require you to run `openproject configure` again to see it in use.

`/etc/openproject` : configuration directory. The wizard feeds itself from the values input to `/etc/openproject/installer.dat` , and it will output ENV variables to separate files within `/etc/openproject/conf.d`. Simply removing values there might not work for that reason.

## Testing a packaging-related bug fix

If you need a package of your changes before they are being merged, simply create a branch with the prefix `packaging/` to allow it being build.

Then, trigger its builds using this URL: `https://packager.io/gh/opf/openproject/refs/BRANCH-NAME`. For example: https://packager.io/gh/opf/openproject/refs/packaging/custom-plugin-frozen

If you're pushing multiple commits and want faster turnover times, reduce the number of available distributions in the `.pkgr.yml` to only the ones you want to test here: https://github.com/opf/openproject/blob/dev/.pkgr.yml

**Important:** Remember to remove those changes before merging!
