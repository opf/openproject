import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { formattingToolbarVisible } from '../../../helpers/editorHelpers';
import { mentionContent, paragraphWith } from '../../../helpers/content';

const NEXT_LINE = 'next line';

const mentionDocument = [
  paragraphWith('before ', mentionContent('7', 'Anna Kovalenko')),
  { type: 'paragraph', content: NEXT_LINE },
];

const pill = () => page.getByRole('button', { name: 'User Anna Kovalenko' });
const optionsMenu = () => page.getByRole('menu', { name: 'Options for the mention of Anna Kovalenko' });
const openItem = () => page.getByRole('menuitem', { name: "Open Anna Kovalenko's profile in new tab" });
const removeItem = () => page.getByRole('menuitem', { name: 'Remove mention' });
const liveRegion = () => document.querySelector('.op-bn-live-region');
const firstParagraphText = () => document.querySelector('.bn-inline-content')?.textContent;

// Placed through the editor: a caret the browser moves natively reaches
// ProseMirror only after a key pressed straight after it has been handled.
async function renderMentionWithCaretBehindIt() {
  let editor:any;
  renderEditor({ initialContent: mentionDocument, onEditor: (created) => { editor = created; } });
  await expect.element(pill()).toBeVisible();

  editor.focus();
  editor.setTextCursorPosition(editor.document[0], 'end');
}

async function selectMentionWithKeyboard() {
  await renderMentionWithCaretBehindIt();
  await userEvent.keyboard('{ArrowLeft}');
}

async function openOptionsWithKeyboard() {
  await selectMentionWithKeyboard();
  await userEvent.keyboard('{Enter}');
  await expect.element(openItem()).toHaveFocus();
}

describe('User mention keyboard access - selecting a mention', () => {
  it('selects the mention with the arrow key before moving past it', async () => {
    await selectMentionWithKeyboard();

    await expect.poll(() => liveRegion()?.textContent)
      .toBe('User Anna Kovalenko. Press Enter to open its options.');

    await userEvent.keyboard('{ArrowLeft}x');
    expect(firstParagraphText()).toMatch(/^before xAnna Kovalenko/);
  });

  it('selects the mention coming from the other side as well', async () => {
    await renderMentionWithCaretBehindIt();
    await userEvent.keyboard('{ArrowLeft}{ArrowLeft}{ArrowRight}');

    await userEvent.keyboard('{Enter}');

    await expect.element(optionsMenu()).toBeVisible();
  });

  it('keeps the formatting toolbar closed while the mention is selected', async () => {
    await selectMentionWithKeyboard();

    await expect.poll(() => liveRegion()?.textContent).not.toBe('');
    expect(formattingToolbarVisible()).toBe(false);
  });
});

describe('User mention keyboard access - the options menu', () => {
  it('opens on Enter and takes the focus onto its first item', async () => {
    await openOptionsWithKeyboard();

    await expect.element(optionsMenu()).toBeVisible();
    expect(firstParagraphText()).toMatch(/^before Anna Kovalenko/);
    await expect.element(page.getByText(NEXT_LINE)).toBeVisible();
  });

  it('opens on Space without replacing the mention', async () => {
    await selectMentionWithKeyboard();

    await userEvent.keyboard(' ');

    await expect.element(openItem()).toHaveFocus();
    expect(firstParagraphText()).toMatch(/^before Anna Kovalenko/);
  });

  it('moves between its items with the arrow keys', async () => {
    await openOptionsWithKeyboard();

    await userEvent.keyboard('{ArrowRight}');
    await expect.element(removeItem()).toHaveFocus();

    await userEvent.keyboard('{ArrowRight}');
    await expect.element(openItem()).toHaveFocus();
  });

  it('closes on Escape and hands the focus back to the editor with the mention still selected', async () => {
    await openOptionsWithKeyboard();

    await userEvent.keyboard('{Escape}');

    await expect.element(optionsMenu()).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveFocus();

    await userEvent.keyboard('{Enter}');
    await expect.element(openItem()).toHaveFocus();
  });

  it('removes the mention from the keyboard and hands the focus back to the editor', async () => {
    await openOptionsWithKeyboard();

    await userEvent.keyboard('{End}{Enter}');

    await expect.element(pill()).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveFocus();
    expect(liveRegion()?.textContent).toBe('');
  });
});
