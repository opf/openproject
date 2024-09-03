---
sidebar_navigation:
  title: Development setup
description: OpenProject development setup
keywords: development setup
---

# OpenProject development setup

| OS/Method                          | Description                                                                       |
|------------------------------------|-----------------------------------------------------------------------------------|
| [Ubuntu / Debian](linux)           | Develop setup on Linux                                                            |
| [via docker](docker)               | The quickest way to get started developing OpenProject is to use the docker setup |
| [via docker (MacOS)](docker-macos) | MacOS specific docker topics                                                      |
| [MacOS](macos)                     | Develop setup on MacOS                                                            |


### Start Coding

Please have a look at [our development guidelines](../code-review-guidelines/) for tips and guides on how to start
coding. We have advice on how to get your changes back into the OpenProject core as smooth as possible.
Also, take a look at the `doc` directory in our sources, especially
the [how to run tests](../running-tests) documentation (we like to have automated tests for every new developed feature).

### Troubleshooting

The OpenProject logfile can be found in `log/development.log`.

If an error occurs, it should be logged there (as well as in the output to STDOUT/STDERR of the rails server process).

### Questions, Comments, and Feedback

If you have any further questions, comments, feedback, or an idea to enhance this guide, please tell us at the
appropriate [forum](https://community.openproject.org/projects/openproject/boards/9).
