# Subversion and Git Integration
OpenProject can (by default) browse Subversion and Git repositories, but it does not serve them to git/svn clients.

We do however support an integration with the Apache webserver to create and serve repositories on the fly, including integration into the fine-grained project authorization system of OpenProject.

--

The repositories integration guide for OpenProject 5.0 has been moved [here](./operation_guides/manual/repository-integration.md).
If you're looking for upgrading existing repository functionality (e.g., the reposman.rb cron job) to OpenProject 5.0, follow the repository section of [the upgrade guide](./operation_guides/manual/upgrade-guide.md).