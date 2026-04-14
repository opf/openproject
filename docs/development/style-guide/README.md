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

## Code comments

Write for readers who know Ruby, Rails, TypeScript, and the patterns used in OpenProject.
Write self-explanatory code instead of comments.

- Default to zero comments. Sparse is the goal, not thorough coverage.
- Never restate what the code plainly does (`# increments the counter` above `counter += 1`).
  These get flagged in review.
- Never justify the chosen approach. If a comment names a rejected alternative
  ("EXISTS rather than a join because…"), delete it — that reasoning belongs in the commit
  message or PR description, not the source.
- Do comment to explain a constraint the code cannot express itself: a workaround for an
  upstream bug, a non-obvious edge case, an ordering requirement, an invariant the caller
  must uphold. Link the work package or upstream issue when there is one.
- Don't add YARD/JSDoc headers to self-descriptive methods. Only where generated
  documentation is actually consumed.
- More than a handful of comments in a file is a smell: extract better-named methods,
  variables, and objects so the code explains itself.
- When in doubt, delete the comment rather than shortening it.
- Use en-us spelling.
