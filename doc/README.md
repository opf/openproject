# Documention source files

This folder contains source files for various documentation formats for OpenProject.
If you are looking for help resources on OpenProject, please see [our guides page](../guides/README.md).

## openproject.org guide sources

All guides in the `wp` folder are sources being processed and concat by Wordpress for being presented on [www.openproject.org](http://www.openproject.org).

The installation guides for OpenProject [can be found on our website](https://www.openproject.org/open-source/download/).


## APIv3 documentation sources

The documentation for APIv3 is written in the [API Blueprint Format](http://apiblueprint.org/) and its sources are being built from the entry point `apiv3-documentation.apib`.

You can use [aglio](https://github.com/danielgtaylor/aglio) to generate HTML documentation, e.g. using the following command:

```bash
aglio -i apiv3-documentation.apib -o api.html
```

The output of the API documentation at `dev` branch is continuously built and pushed to Github Pages at [opf.github.io/apiv3-doc/](opf.github.io/apiv3-doc/).