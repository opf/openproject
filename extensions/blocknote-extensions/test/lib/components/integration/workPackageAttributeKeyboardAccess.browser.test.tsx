import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { selectBlockNode } from '../../../../lib/utils/selection';
import type { AnyEditor } from '../../../../lib/editorTypes';

const inlineStatus = {
  type: 'openProjectWorkPackageAttributeInline',
  props: { wpid: '321', displayId: 'PROJ-321', attribute: 'status', display: 'value' },
};

const longText = {
  type: 'openProjectWorkPackageAttributeBlock',
  props: { wpid: '321', displayId: 'PROJ-321', attribute: 'description', display: 'value' },
};

const optionsMenu = (attribute:string) => page.getByRole('menu', { name: `Options for ${attribute} of work package PROJ-321` });
const openItem = () => page.getByRole('menuitem', { name: 'Open work package PROJ-321 in new tab' });
const sizeItem = () => page.getByRole('menuitem', { name: /^Change size/ });
const removeItem = () => page.getByRole('menuitem', { name: 'Remove work package attribute' });
const liveRegion = () => document.querySelector('.op-bn-live-region');

interface InlineNode { type:string, text?:string, props?:Record<string, unknown> }

function inlineNodes(editor:AnyEditor, blockIndex = 0):InlineNode[] {
  return (editor.document[blockIndex].content ?? []) as InlineNode[];
}

function inlineAttributes(editor:AnyEditor) {
  return inlineNodes(editor)
    .filter((node) => node.type === 'openProjectWorkPackageAttributeInline')
    .map((node) => node.props);
}

async function selectInlineAttributeWithKeyboard({ editable = true } = {}):Promise<AnyEditor> {
  let editor!:AnyEditor;
  renderEditor({
    editable,
    initialContent: [{ type: 'paragraph', content: ['before ', inlineStatus] }, { type: 'paragraph', content: 'next line' }],
    onEditor: (created) => { editor = created; },
  });
  await expect.element(page.getByText('In progress')).toBeVisible();

  editor.focus();
  editor.setTextCursorPosition(editor.document[0], 'end');
  await userEvent.keyboard('{ArrowLeft}');
  return editor;
}

describe('Work package attribute keyboard access - an inline attribute', () => {
  it('is selected with the arrow key before moving past it, and says how to open its options', async () => {
    const editor = await selectInlineAttributeWithKeyboard();

    await expect.poll(() => liveRegion()?.textContent)
      .toBe('Status of work package PROJ-321. Press Enter to open its options.');

    await userEvent.keyboard('{ArrowLeft}x');
    expect(inlineNodes(editor)[0].text).toBe('before x');
  });

  it('opens its options on Enter with the focus on the first item, and hands the focus back on Escape', async () => {
    await selectInlineAttributeWithKeyboard();

    await userEvent.keyboard('{Enter}');
    await expect.element(optionsMenu('Status')).toBeVisible();
    await expect.element(openItem()).toHaveFocus();

    await userEvent.keyboard('{Escape}');
    await expect.element(optionsMenu('Status')).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveFocus();
  });

  it('changes what it shows from the keyboard', async () => {
    const editor = await selectInlineAttributeWithKeyboard();
    await userEvent.keyboard('{Enter}');
    await expect.element(openItem()).toHaveFocus();

    await userEvent.keyboard('{ArrowRight}');
    await expect.element(sizeItem()).toHaveAccessibleName('Change size: Value');
    await userEvent.keyboard('{Enter}');
    const value = page.getByRole('menuitemradio', { name: 'Value', exact: true });
    await expect.element(value).toHaveFocus();
    await expect.element(value).toHaveAttribute('aria-checked', 'true');

    await userEvent.keyboard('{ArrowDown}{Enter}');

    await expect.element(page.getByRole('button', { name: 'Status: In progress' })).toBeVisible();
    expect(inlineAttributes(editor)[0]).toMatchObject({ display: 'both' });
    await expect.element(page.getByRole('textbox')).toHaveFocus();
  });

  it('is removed from the keyboard', async () => {
    const editor = await selectInlineAttributeWithKeyboard();
    await userEvent.keyboard('{Enter}');
    await expect.element(openItem()).toHaveFocus();

    await userEvent.keyboard('{End}');
    await expect.element(removeItem()).toHaveFocus();
    await userEvent.keyboard('{Enter}');

    await expect.poll(() => inlineAttributes(editor)).toEqual([]);
    await expect.element(page.getByRole('textbox')).toHaveFocus();
  });

  it('offers no options in a read-only editor', async () => {
    await selectInlineAttributeWithKeyboard({ editable: false });

    await userEvent.keyboard('{Enter}');

    expect(document.querySelector('[data-testid="popover-content"]')).toBeNull();
  });
});

describe('Work package attribute keyboard access - a long text', () => {
  it('opens its options on Enter once selected', async () => {
    let editor!:AnyEditor;
    renderEditor({
      initialContent: [{ type: 'paragraph', content: 'above' }, longText],
      onEditor: (created) => { editor = created; },
    });
    await expect.element(page.getByText('Kick-off')).toBeVisible();

    editor.focus();
    selectBlockNode(editor, editor.document[1].id);
    await expect.poll(() => liveRegion()?.textContent)
      .toBe('Description of work package PROJ-321. Press Enter to open its options.');

    await userEvent.keyboard('{Enter}');

    await expect.element(optionsMenu('Description')).toBeVisible();
    await expect.element(openItem()).toHaveFocus();
  });
});
