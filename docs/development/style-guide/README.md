# OpenProject development style guide

- [Frontend](./frontend/)

## Copyright notices

Use [bin/copycop](https://github.com/opf/openproject/blob/dev/bin/copycop) to check, generate, or repair copyright notices from [COPYRIGHT_short](https://github.com/opf/openproject/blob/dev/COPYRIGHT_short). Pass files or directories to check; without paths, it applies to the current directory:

```shell
bin/copycop path/to/file_or_directory     # check
bin/copycop -a path/to/file_or_directory  # insert or update notices where it is safe
bin/copycop -A path/to/file_or_directory  # also apply unsafe corrections, review carefully
```

[.copycop.yml](https://github.com/opf/openproject/blob/dev/.copycop.yml) defines the comment style per file type and the ignored paths. A directory can have its own `COPYRIGHT_short`, or an alternative copyright file listed in `.copycop.yml`, which applies to the files below it.

If copycop has no style defined for the file type, add one to `.copycop.yml`. If that is not possible, manually copy a notice from a first-party OpenProject file of the same type. Preserve third-party copyright notices and add such files to the ignored paths.
