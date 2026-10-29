import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import type { AnyEditor } from '../../../../lib/editorTypes';
import { selectBlockNode } from '../../../../lib/utils/selection';
import { openBlockWorkPackageSearch, openEditorAndType, SEARCH_PLACEHOLDER } from '../../../helpers/editorHelpers';

// A block without a work package that this client did not insert: another client's
// open search, or one left behind by a reload while the search was open.
async function renderBetweenTwoLines():Promise<AnyEditor> {
  let renderedEditor:AnyEditor | undefined;
  renderEditor({ onEditor: (created) => { renderedEditor = created; } });
  await expect.element(page.getByRole('textbox')).toBeVisible();
  const editor = renderedEditor!;
  editor.replaceBlocks(editor.document, [
    { type: 'paragraph', content: 'above' },
    { type: 'openProjectWorkPackageBlock', props: {} },
    { type: 'paragraph', content: 'below' },
  ]);
  return editor;
}

async function renderBetweenTwoCards():Promise<AnyEditor> {
  let renderedEditor:AnyEditor | undefined;
  renderEditor({ onEditor: (created) => { renderedEditor = created; } });
  await expect.element(page.getByRole('textbox')).toBeVisible();
  const editor = renderedEditor!;
  editor.replaceBlocks(editor.document, [
    { type: 'openProjectWorkPackageBlock', props: { wpid: 123 } },
    { type: 'openProjectWorkPackageBlock', props: {} },
    { type: 'openProjectWorkPackageBlock', props: { wpid: 123 } },
    { type: 'paragraph', content: 'below' },
  ]);
  await expect.poll(() => page.getByTestId('block-card').all().length).toBe(2);
  return editor;
}

const selectedBlockId = (editor:AnyEditor) => {
  const { selection } = editor.prosemirrorView.state;
  return 'node' in selection ? (selection.$from.parent.attrs as { id:string }).id : undefined;
};

// Between two cards ProseMirror first stops on a gap cursor, so keep pressing until a card is selected.
async function nextSelectedBlockId(editor:AnyEditor, key:string):Promise<string | undefined> {
  for (let presses = 0; presses < 3; presses++) {
    await userEvent.keyboard(key);
    const blockId = selectedBlockId(editor);
    if (blockId) return blockId;
  }
  return undefined;
}

const paragraphTexts = (editor:AnyEditor) => editor.document
  .filter((block) => block.type === 'paragraph')
  .map((block) => (block.content as { text:string }[]).map((part) => part.text).join(''));

describe('Work package block without a card (BNE-181)', () => {
  it('is stepped over downwards, so typing lands in the line below', async () => {
    const editor = await renderBetweenTwoLines();
    editor.setTextCursorPosition(editor.document[0].id, 'end');
    editor.focus();

    await userEvent.keyboard('{ArrowDown}');
    await userEvent.keyboard('x');

    expect(paragraphTexts(editor)).toEqual(['above', 'xbelow']);
  });

  it('is stepped over upwards, so typing lands in the line above', async () => {
    const editor = await renderBetweenTwoLines();
    editor.setTextCursorPosition(editor.document[2].id, 'start');
    editor.focus();

    await userEvent.keyboard('{ArrowUp}');
    await userEvent.keyboard('x');

    expect(paragraphTexts(editor)).toEqual(['abovex', 'below']);
  });

  it('stops at the card right below it', async () => {
    const editor = await renderBetweenTwoCards();
    selectBlockNode(editor, editor.document[0].id);
    editor.focus();

    expect(await nextSelectedBlockId(editor, '{ArrowDown}')).toBe(editor.document[2].id);
  });

  it('stops at the card right above it', async () => {
    const editor = await renderBetweenTwoCards();
    selectBlockNode(editor, editor.document[2].id);
    editor.focus();

    expect(await nextSelectedBlockId(editor, '{ArrowUp}')).toBe(editor.document[0].id);
  });
});

describe('Leaving the page while a work package is being chosen (BNE-181)', () => {
  const leaveThePage = () => window.dispatchEvent(new PageTransitionEvent('pagehide'));

  it('gives the line back instead of leaving an empty block behind', async () => {
    let renderedEditor:AnyEditor | undefined;
    renderEditor({ onEditor: (created) => { renderedEditor = created; } });
    await openBlockWorkPackageSearch();

    leaveThePage();

    await expect.poll(() => renderedEditor!.document.map((block):string => block.type as string)).toEqual(['paragraph']);
  });

  it('drops the pending inline work package', async () => {
    let renderedEditor:AnyEditor | undefined;
    renderEditor({ onEditor: (created) => { renderedEditor = created; } });
    await openEditorAndType('text /');
    await userEvent.click(page.getByText('Link existing work package').first());
    await expect.element(page.getByPlaceholder(SEARCH_PLACEHOLDER)).toBeVisible();

    leaveThePage();

    await expect.poll(() => (renderedEditor!.document[0].content as { type:string }[]).map((part) => part.type))
      .toEqual(['text']);
  });
});
