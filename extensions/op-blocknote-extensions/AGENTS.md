## Commands
- run (all) tests: `npm run test` (uses vitest)
- build: `npm run build` (uses vite)
- lint & format: `npm run lint` (uses eslint)
Don't try to use prettier!

## Pull requests and commits
- Use the form "[<ticket ID>] description" for commit and pull request titles
- Keep commit and pull request descriptions short and concise
    - Include at least one body line unless the commit is a one-line mechanical
      change with no useful rationale to record.
    - Focus on *why*, not *what* in the PR description (the diff shows what). Don't enumerate implementation details.
- For bug fixes, always put root cause and the chosen solution in the commit description

## Coding guidelines
- Always add tests for all changes. For new features, also always add an integration (browser) test. For bugs it can be sufficient to only add a unit test (depending on the bug).
- Avoid to use abbreviations for variable names unless it's beneficial because the line gets too long otherwise
- Write code like a senior developer would
- Always try to solve the requirements by using BlockNote's built-in features / API. Always check the [BlockNote documentation](https://www.blocknotejs.org/docs) or [source code](https://github.com/TypeCellOS/BlockNote/) before using Prosemirror or Tiptap. Only use Prosemirror or Tiptap if there absolutely is not other way to achieve the requirements.
- Always write code that passes our linting rules (see eslint.config.js)
- Always ensure the tests pass and the build works after making changes
- Always try to be consistent with naming (e.g. of variables and CSS classes)

## Architectural guidelines
- This repo here is used in OpenProject (https://github.com/opf/openproject) in two places:
    1. In the documents module in a BlockNote editor which is used by users and renders the work package links as react components (see frontend/src/react/components/OpBlockNoteEditor.tsx)
    2. In the Hocuspocus extension which is used for real-time collaboration and saving the document (as ydoc and as markdown file) (see extensions/op-blocknote-hocuspocus/src/extensions/openProjectApi.ts). It needs to render a non-react static representation of the data there.
- The interface how op-blocknote-extensions is initialized and used in BlockNote needs to be kept stable (method `initializeOpBlockNoteExtensions`). It should be changed only if it is really necessary and can not be avoided.
