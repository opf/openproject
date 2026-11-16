## Commands
- run (all) tests: `npm run test` (uses vitest)
- build: `npm run build` (uses vite)
- lint & format: `npm run lint` (uses eslint)
Don't try to use prettier!

## Pull requests and commits
- Follow the general [commit message convention](../../docs/development/code-review-guidelines/README.md#structure-of-commit-messages); use the same work package prefix for pull request titles
- Keep pull request descriptions short: focus on *why*, not *what* (the diff shows what). Don't enumerate implementation details.
- For bug fixes, always put root cause and the chosen solution in the commit description
- Add an entry for every user-facing change to the `Unreleased` section of [CHANGELOG.md](CHANGELOG.md) in the same pull request

## Coding guidelines
- Always add tests for all changes. For new features, also always add an integration (browser) test. For bugs it can be sufficient to only add a unit test (depending on the bug).
- Whenever a test needs an editor, always use the shared test editor setup (`test/helpers/renderEditor.tsx`) and the shared helpers in `test/helpers/editorHelpers.ts`. Never add another editor setup, and never hand-roll a fake editor object. Only if a test really, really needs a different setup, use one and document the reason in a comment.
- Avoid to use abbreviations for variable names unless it's beneficial because the line gets too long otherwise
- Write code like a senior developer would
- Always try to solve the requirements by using BlockNote's built-in features / API first. Always check the [BlockNote documentation](https://www.blocknotejs.org/docs) or [source code](https://github.com/TypeCellOS/BlockNote/) before using Prosemirror or Tiptap. Only use Prosemirror or Tiptap if the requirements can not be achieved with BlockNote directly.
- Always write code that passes our linting rules (see eslint.config.js)
- Always ensure the tests pass and the build works after making changes
- Always try to be consistent with naming (e.g. of variables and CSS classes)

## Architectural guidelines
- This extension is used in two places:
    1. In the documents module in a BlockNote editor which is used by users and renders the work package links as react components (see frontend/src/react/components/OpBlockNoteEditor.tsx)
    2. In the Hocuspocus extension which is used for real-time collaboration and saving the document (as yDoc and as Markdown file) (see extensions/op-blocknote-hocuspocus/src/extensions/openProjectApi.ts). It needs to render a non-react static representation of the data there.
- The interface how @openproject/blocknote-extensions is initialized and used in BlockNote or e.g. OpenProject needs to be kept stable.
- The extension has to be kept separate from OpenProject. We have to ensure it would also work with 3rd party applications which use BlockNote and want to integrate with OpenProject. So do not depend on OpenProject except for loading and writing data via the API.
