# OpenProject development style guide

- [Frontend](./frontend/)

## Copyright notices

Use the applicable `copyright:update_*` Rake task or ESLint autofix to generate or repair copyright notices from [COPYRIGHT_short](https://github.com/opf/openproject/blob/dev/COPYRIGHT_short). The [Rake tasks](https://github.com/opf/openproject/blob/dev/lib/tasks/copyright.rake) list the available updaters; some only update existing notices.

For Ruby, JavaScript, and TypeScript, run the matching task from the repository root. Replace `path/to/directory` with the directory containing the files to update:

```shell
bundle exec rake 'copyright:update_rb[path/to/directory]'
bundle exec rake 'copyright:update_js[path/to/directory]'
bundle exec rake 'copyright:update_typescript[path/to/directory]'
```

The JavaScript task covers `.js`, `.mjs`, and `.cjs`; the TypeScript task covers `.ts` and `.tsx`. Both generate the canonical compact line-comment header, including its markers and the blank line before the source code. For frontend files covered by the copyright header rule, `npx eslint --fix path/to/file` from `frontend/` can also repair the notice.

If neither tool can add a missing notice for the file type, manually copy one from a first-party OpenProject file of the same type and use the appropriate comment syntax. This includes file types whose Rake task only updates existing notices, such as CSS and HTML ERB. Preserve third-party copyright notices.
