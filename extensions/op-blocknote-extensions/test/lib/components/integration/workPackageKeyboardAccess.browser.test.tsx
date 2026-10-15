import { describe, it, expect, onTestFinished } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { worker } from '../../../mocks/browser';
import { mockWorkPackage } from '../../../mocks/handlers';
import { renderEditor, renderEditorInShadowDom } from '../../../helpers/renderEditor';
import {
  formattingToolbarVisible,
  openBlockCardPopover,
  openInlineWorkPackagePopover,
} from '../../../helpers/editorHelpers';

const NEXT_LINE = 'next line';

const chipDocument = [
  {
    type: 'paragraph',
    content: [
      'before ',
      { type: 'openProjectWorkPackageInline', props: { wpid: '123', size: 's', displayId: '123' } },
    ],
  },
  { type: 'paragraph', content: NEXT_LINE },
];

const blockDocument = [
  { type: 'paragraph', content: 'above' },
  { type: 'openProjectWorkPackageBlock', props: { wpid: 123, size: 'm', displayId: '123' } },
];

// Placed through the editor: a caret the browser moves natively reaches
// ProseMirror only after a key pressed straight after it has been handled.
function putCaretBehindChip(editor:any) {
  editor.focus();
  editor.setTextCursorPosition(editor.document[0], 'end');
}

async function renderChipWithCaretBehindIt() {
  let editor:any;
  renderEditor({ initialContent: chipDocument, onEditor: (created) => { editor = created; } });
  await expect.element(page.getByText('#123', { exact: true })).toBeVisible();

  putCaretBehindChip(editor);
}

async function selectChipWithKeyboard() {
  await renderChipWithCaretBehindIt();
  await userEvent.keyboard('{ArrowLeft}');
}

const optionsMenu = () => page.getByRole('menu', { name: 'Options for work package #123' });
const openItem = () => page.getByRole('menuitem', { name: 'Open work package #123 in new tab' });
const sizeItem = () => page.getByRole('menuitem', { name: /^Change size/ });
const removeItem = () => page.getByRole('menuitem', { name: 'Remove work package' });
const liveRegion = () => document.querySelector('.op-bn-live-region');
const firstParagraphText = () => document.querySelector('.bn-inline-content')?.textContent;

describe('Work package keyboard access - selecting an inline chip', () => {
  it('selects the chip with the arrow key before moving past it', async () => {
    await selectChipWithKeyboard();

    await expect.poll(() => liveRegion()?.textContent)
      .toBe('Work package #123, Bug, In Progress, Fix login bug. Press Enter to open its options.');

    await userEvent.keyboard('{ArrowLeft}x');
    expect(firstParagraphText()).toMatch(/^before x#123/);
  });

  it('announces a chip selected while it was still loading once it has loaded', async () => {
    let respond = () => {};
    const responded = new Promise<void>((resolve) => { respond = resolve; });
    worker.use(http.get('http://localhost:3000/api/v3/work_packages/123', async () => {
      await responded;
      return HttpResponse.json(mockWorkPackage);
    }));
    onTestFinished(() => worker.resetHandlers());

    let editor:any;
    renderEditor({ initialContent: chipDocument, onEditor: (created) => { editor = created; } });
    await expect.element(page.getByText('#123…')).toBeVisible();

    putCaretBehindChip(editor);
    await userEvent.keyboard('{ArrowLeft}');
    respond();

    await expect.poll(() => liveRegion()?.textContent)
      .toBe('Work package #123, Bug, In Progress, Fix login bug. Press Enter to open its options.');
  });

  it('keeps the formatting toolbar closed while the chip is selected', async () => {
    await selectChipWithKeyboard();
    await expect.poll(() => liveRegion()?.textContent).not.toBe('');

    expect(formattingToolbarVisible()).toBe(false);
  });

  it('selects the chip coming from the other side as well', async () => {
    await renderChipWithCaretBehindIt();
    await userEvent.keyboard('{ArrowLeft}{ArrowLeft}{ArrowRight}');

    await userEvent.keyboard('{Enter}');

    await expect.element(optionsMenu()).toBeVisible();
  });
});

describe('Work package keyboard access - the options menu of an inline chip', () => {
  it('opens on Enter and takes the focus onto its first item', async () => {
    await selectChipWithKeyboard();

    await userEvent.keyboard('{Enter}');

    await expect.element(optionsMenu()).toBeVisible();
    await expect.element(openItem()).toHaveFocus();
    expect(firstParagraphText()).toMatch(/^before #123/);
    await expect.element(page.getByText(NEXT_LINE)).toBeVisible();
  });

  it('opens on Space without replacing the chip', async () => {
    await selectChipWithKeyboard();

    await userEvent.keyboard(' ');

    await expect.element(openItem()).toHaveFocus();
    expect(firstParagraphText()).toMatch(/^before #123/);
  });

  it('moves between its items with the arrow keys, Home and End', async () => {
    await selectChipWithKeyboard();
    await userEvent.keyboard('{Enter}');
    await expect.element(openItem()).toHaveFocus();

    await userEvent.keyboard('{ArrowRight}');
    await expect.element(sizeItem()).toHaveFocus();

    await userEvent.keyboard('{End}');
    await expect.element(removeItem()).toHaveFocus();

    await userEvent.keyboard('{ArrowRight}');
    await expect.element(openItem()).toHaveFocus();

    await userEvent.keyboard('{ArrowLeft}');
    await expect.element(removeItem()).toHaveFocus();

    await userEvent.keyboard('{Home}');
    await expect.element(openItem()).toHaveFocus();
  });

  it('closes on Escape and hands the focus back to the editor with the chip still selected', async () => {
    await selectChipWithKeyboard();
    await userEvent.keyboard('{Enter}');
    await expect.element(openItem()).toHaveFocus();

    await userEvent.keyboard('{Escape}');

    await expect.element(optionsMenu()).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveFocus();

    await userEvent.keyboard('{Enter}');
    await expect.element(openItem()).toHaveFocus();
  });

  it('closes on Tab and hands the focus back to the editor', async () => {
    await selectChipWithKeyboard();
    await userEvent.keyboard('{Enter}');
    await expect.element(openItem()).toHaveFocus();

    await userEvent.keyboard('{Tab}');

    await expect.element(optionsMenu()).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveFocus();
  });

  it('changes the size from the keyboard', async () => {
    await selectChipWithKeyboard();
    await userEvent.keyboard('{Enter}{ArrowRight}');
    await expect.element(sizeItem()).toHaveAccessibleName('Change size: Regular');

    await userEvent.keyboard('{Enter}');
    const regular = page.getByRole('menuitemradio', { name: 'Regular' });
    await expect.element(regular).toHaveFocus();
    await expect.element(regular).toHaveAttribute('aria-checked', 'true');

    await userEvent.keyboard('{ArrowUp}{Enter}');

    await expect.element(optionsMenu()).not.toBeInTheDocument();
    await expect.element(page.getByText('In Progress', { exact: true })).not.toBeInTheDocument();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByRole('textbox')).toHaveFocus();
  });

  it('closes only the size menu on Escape and puts the focus back on the item that opened it', async () => {
    await selectChipWithKeyboard();
    await userEvent.keyboard('{Enter}{ArrowRight}{Enter}');
    await expect.element(page.getByRole('menuitemradio', { name: 'Regular' })).toHaveFocus();

    await userEvent.keyboard('{Escape}');

    await expect.element(page.getByTestId('size-menu')).not.toBeInTheDocument();
    await expect.element(sizeItem()).toHaveFocus();
    await expect.element(sizeItem()).toHaveAttribute('aria-expanded', 'false');
  });

  it('removes the chip from the keyboard and hands the focus back to the editor', async () => {
    await selectChipWithKeyboard();
    await userEvent.keyboard('{Enter}{End}{Enter}');

    await expect.element(page.getByText('#123', { exact: true })).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveFocus();
    expect(liveRegion()?.textContent).toBe('');
  });

  it('leaves the focus in the editor when a pointer opened it, and keeps it there on Escape', async () => {
    renderEditor({ initialContent: chipDocument });
    await openInlineWorkPackagePopover();

    await expect.element(page.getByRole('textbox')).toHaveFocus();

    await userEvent.keyboard('{Escape}');
    await expect.element(optionsMenu()).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveFocus();
  });

  it('only closes on Tab when a pointer opened it, instead of moving the focus on', async () => {
    renderEditor({ initialContent: chipDocument });
    await openInlineWorkPackagePopover();

    await userEvent.keyboard('{Tab}');

    await expect.element(optionsMenu()).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveFocus();
  });

  it('draws its own focus ring on the item in focus, whatever the host page does to focused buttons', async () => {
    // What OpenProject's stylesheet does inside the editor's shadow root: its
    // outline names a colour variable that is not defined there.
    const hostStyles = document.createElement('style');
    hostStyles.textContent = 'button:focus-visible { outline: 2px solid var(--undefined-host-color); }';
    document.head.appendChild(hostStyles);
    onTestFinished(() => hostStyles.remove());

    await selectChipWithKeyboard();
    await userEvent.keyboard('{Enter}');
    await expect.element(openItem()).toHaveFocus();
    expect(getComputedStyle(openItem().element()).outline).toBe('rgb(100, 160, 255) solid 2px');

    await userEvent.keyboard('{ArrowRight}{Enter}');
    const regular = page.getByRole('menuitemradio', { name: 'Regular' });
    await expect.element(regular).toHaveFocus();
    expect(getComputedStyle(regular.element()).outline).toBe('rgb(100, 160, 255) solid 2px');
  });

  it('works inside a shadow root', async () => {
    let editor:any;
    const { shadowRoot } = await renderEditorInShadowDom({
      initialContent: chipDocument,
      onEditor: (created) => { editor = created; },
    });
    await expect.element(page.getByText('#123', { exact: true })).toBeVisible();
    // toHaveFocus compares against document.activeElement, which is only the shadow host.
    const focused = () => shadowRoot.activeElement;

    putCaretBehindChip(editor);
    await userEvent.keyboard('{ArrowLeft}{Enter}');

    await expect.poll(focused).toBe(openItem().element());

    await userEvent.keyboard('{Escape}');
    await expect.poll(focused).toBe(page.getByRole('textbox').element());
  });
});

describe('Work package keyboard access - what a screen reader is told about an inline chip', () => {
  it('exposes the identifier as the button that opens the options, next to the subject link', async () => {
    renderEditor({ initialContent: chipDocument });
    const menuButton = page.getByRole('button', { name: 'Work package #123' });
    await expect.element(menuButton).toBeVisible();

    await expect.element(menuButton).toHaveAttribute('aria-haspopup', 'menu');
    await expect.element(menuButton).toHaveAttribute('aria-expanded', 'false');

    const subject = page.getByRole('link', { name: 'Fix login bug' });
    await expect.element(subject).toBeVisible();
    expect(subject.element().closest('[role="button"]')).toBeNull();

    await openInlineWorkPackagePopover();
    await expect.element(menuButton).toHaveAttribute('aria-expanded', 'true');
  });
});

describe('Work package keyboard access - a block card', () => {
  it('is selected with the arrow key and opens its options on Enter', async () => {
    renderEditor({ initialContent: blockDocument });
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    await userEvent.click(page.getByText('above'));
    await userEvent.keyboard('{End}{ArrowDown}');

    await expect.poll(() => liveRegion()?.textContent)
      .toBe('Work package #123, Bug, In Progress, Fix login bug. Press Enter to open its options.');
    expect(formattingToolbarVisible()).toBe(false);

    await userEvent.keyboard('{Enter}');

    await expect.element(openItem()).toHaveFocus();
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    await userEvent.keyboard('{Escape}');
    await expect.element(page.getByRole('textbox')).toHaveFocus();
  });

  it('only closes on Tab when a pointer opened it, instead of nesting the block', async () => {
    let editor:any;
    renderEditor({ initialContent: blockDocument, onEditor: (created) => { editor = created; } });
    await openBlockCardPopover();

    await userEvent.keyboard('{Tab}');

    await expect.element(optionsMenu()).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveFocus();
    expect(editor.document.map((block:{ type:string }) => block.type)).toContain('openProjectWorkPackageBlock');
  });

  it('exposes the identifier as the button that opens the options, next to the subject link', async () => {
    renderEditor({ initialContent: blockDocument });
    const card = page.getByTestId('block-card');
    await expect.element(card).toBeVisible();

    expect(card.element().getAttribute('role')).toBeNull();

    const menuButton = card.getByRole('button', { name: 'Work package #123' });
    await expect.element(menuButton).toHaveAttribute('aria-haspopup', 'menu');

    const subject = card.getByRole('link', { name: 'Fix login bug' });
    expect(subject.element().closest('[role="button"]')).toBeNull();
  });
});
