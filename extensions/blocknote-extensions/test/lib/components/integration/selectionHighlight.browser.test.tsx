import { describe, it, expect, afterEach, vi } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { NodeSelection, TextSelection } from 'prosemirror-state';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertBlockWorkPackageViaSlashMenu,
  insertInlineWorkPackageViaSlashMenu,
  openBlockWorkPackageSearch,
  openInlineWorkPackagePopover,
} from '../../../helpers/editorHelpers';
import { hideSafariPhantomSelection } from '../../../../lib/utils/selection';
import type { AnyEditor } from '../../../../lib/editorTypes';

const blockIsSelected = () =>
  document.querySelector('[data-testid="block-wp-wrapper"][data-selected]') !== null;

describe('Block WP – blue border on focus (BNE-95)', () => {
  it('shows border when clicked after typing text below the block', async () => {
    renderEditor();
    await insertBlockWorkPackageViaSlashMenu();

    // cursor lands below the block after insertion – press Enter twice then type
    await userEvent.keyboard('{Enter}{Enter}');
    await userEvent.keyboard('some text');

    await userEvent.click(page.getByTestId('block-wp-wrapper'));
    await expect.poll(blockIsSelected).toBe(true);
  });

  it('shows border when clicked after typing text above the block (exact BNE-95 scenario)', async () => {
    renderEditor();
    const editorEl = page.getByRole('textbox');
    await userEvent.click(editorEl);

    // type text first, then insert WP block below – text is now ABOVE the block
    await userEvent.keyboard('some text{Enter}');
    await insertBlockWorkPackageViaSlashMenu();

    // move cursor to the text above
    await userEvent.click(page.getByText('some text'));

    await userEvent.click(page.getByTestId('block-wp-wrapper'));
    await expect.poll(blockIsSelected).toBe(true);
  });

  it('does not mark the card below the gap cursor between two cards as selected', async () => {
    const card = { type: 'openProjectWorkPackageBlock', props: { wpid: 123 } };
    renderEditor({ initialContent: [{ type: 'paragraph', content: 'above' }, card, card] });
    await expect.poll(() => document.querySelectorAll('[data-testid="block-card"]').length).toBe(2);

    await userEvent.click(page.getByText('above'));
    await userEvent.keyboard('{End}{ArrowDown}{ArrowDown}');
    await expect.poll(() => document.querySelector('.ProseMirror-gapcursor')).not.toBeNull();

    const selectedFlags = [...document.querySelectorAll('[data-testid="block-wp-wrapper"]')]
      .map((wrapper) => wrapper.hasAttribute('data-selected'));
    expect(selectedFlags).toEqual([false, false]);
  });
});

const inlineWorkPackage = { type: 'openProjectWorkPackageInline', props: { wpid: '123', size: 's', displayId: '123' } };
const inlineAttribute = {
  type: 'openProjectWorkPackageAttributeInline',
  props: { wpid: '321', displayId: 'PROJ-321', attribute: 'status', display: 'value' },
};

async function renderAndWaitFor(initialContent:unknown[], ownElement:string) {
  let editor:AnyEditor | undefined;
  renderEditor({ initialContent, onEditor: (created) => { editor = created; } });
  await expect.poll(() => document.querySelector(ownElement)).not.toBeNull();
  return editor!;
}

async function selectInlineWithArrowKey(initialContent:unknown[], ownElement:string) {
  const editor = await renderAndWaitFor(initialContent, ownElement);
  const view = editor.prosemirrorView;
  let positionAfter = -1;
  view.state.doc.descendants((node, position) => {
    if (node.isInline && !node.isText) positionAfter = position + node.nodeSize;
  });
  editor.focus();
  view.dispatch(view.state.tr.setSelection(TextSelection.create(view.state.doc, positionAfter)));

  await userEvent.keyboard('{ArrowLeft}');
}

async function selectBlockWithArrowKey(block:object, ownElement:string) {
  const editor = await renderAndWaitFor([{ type: 'paragraph', content: 'above' }, block], ownElement);
  editor.focus();
  editor.setTextCursorPosition(editor.document[0], 'end');

  await userEvent.keyboard('{ArrowDown}');
}

async function selectionOverlaysAround(ownElement:string) {
  const element = document.querySelector(ownElement)!;
  await expect.poll(() => element.closest('.ProseMirror-selectednode')).not.toBeNull();
  const selectedNode = element.closest('.ProseMirror-selectednode')!;
  return [element, selectedNode].map((candidate) => getComputedStyle(candidate, '::after').content);
}

const noOverlays = ['none', 'none'];

describe('Work package elements - only their own selection ring (BNE-180)', () => {
  it('shows no BlockNote overlay on a block work package', async () => {
    await selectBlockWithArrowKey(
      { type: 'openProjectWorkPackageBlock', props: { wpid: 123, size: 'm', displayId: '123' } },
      '[data-testid="block-wp-wrapper"]',
    );

    expect(await selectionOverlaysAround('[data-testid="block-wp-wrapper"]')).toEqual(noOverlays);
    expect(blockIsSelected()).toBe(true);
  });

  it('shows no BlockNote overlay on a work package attribute block', async () => {
    await selectBlockWithArrowKey(
      {
        type: 'openProjectWorkPackageAttributeBlock',
        props: { wpid: '321', displayId: 'PROJ-321', attribute: 'description', display: 'value' },
      },
      '.op-bn-wp-attribute-block',
    );

    expect(await selectionOverlaysAround('.op-bn-wp-attribute-block')).toEqual(noOverlays);
  });

  it('shows no BlockNote overlay on an inline work package', async () => {
    await selectInlineWithArrowKey([{ type: 'paragraph', content: ['before ', inlineWorkPackage] }], '.op-bn-inline-wp');

    expect(await selectionOverlaysAround('.op-bn-inline-wp')).toEqual(noOverlays);
  });

  it('shows no BlockNote overlay on an inline work package attribute', async () => {
    await selectInlineWithArrowKey([{ type: 'paragraph', content: ['before ', inlineAttribute] }], '.op-bn-wp-attribute');

    expect(await selectionOverlaysAround('.op-bn-wp-attribute')).toEqual(noOverlays);
  });

  it('shows no BlockNote overlay on an inline work package inside a table', async () => {
    const table = {
      type: 'table',
      content: { type: 'tableContent', rows: [{ cells: [['before ', inlineWorkPackage]] }] },
    };
    await selectInlineWithArrowKey([table], '.op-bn-inline-wp');

    expect(await selectionOverlaysAround('.op-bn-inline-wp')).toEqual(noOverlays);
  });
});

const blockSelectionRing = () =>
  getComputedStyle(document.querySelector('[data-testid="block-wp-wrapper"]')!).boxShadow;

describe('Block WP – no selection ring without a card (BNE-181)', () => {
  it('draws no ring while the own search is still open', async () => {
    renderEditor();
    await openBlockWorkPackageSearch();

    await expect.poll(blockIsSelected).toBe(true);
    expect(blockSelectionRing()).toBe('none');
  });
});

const SAFARI_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.5 Safari/605.1.15';
const CHROME_USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36';

const pretendToBeSafari = () => vi.spyOn(navigator, 'userAgent', 'get').mockReturnValue(SAFARI_USER_AGENT);
const pretendNotToBeSafari = () => vi.spyOn(navigator, 'userAgent', 'get').mockReturnValue(CHROME_USER_AGENT);

const nativeSelectionIsCollapsed = () => window.getSelection()?.isCollapsed;

const afterCollapseFrame = () =>
  new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));

describe('Work package selection - no phantom text selection (BNE-125)', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('collapses the phantom selection when an inline chip is clicked', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    pretendToBeSafari();

    await openInlineWorkPackagePopover();

    await expect.poll(nativeSelectionIsCollapsed).toBe(true);
  });

  it('collapses the phantom selection when the card is clicked', async () => {
    renderEditor();
    await insertBlockWorkPackageViaSlashMenu();
    await expect.element(page.getByTestId('block-wp-wrapper')).toBeVisible();
    pretendToBeSafari();

    await userEvent.click(page.getByTestId('op-bn-work-package--type'));

    await expect.poll(blockIsSelected).toBe(true);
    await expect.poll(nativeSelectionIsCollapsed).toBe(true);
  });

  it('collapses the phantom selection when a selection already spanned the card', async () => {
    renderEditor();
    const editorEl = page.getByRole('textbox');
    await userEvent.click(editorEl);
    await userEvent.keyboard('above{Enter}');
    await insertBlockWorkPackageViaSlashMenu();
    await userEvent.keyboard('{Enter}below');

    await userEvent.click(page.getByText('above'));
    await userEvent.keyboard('{Home}');
    await userEvent.keyboard('{Shift>}{ArrowDown}{ArrowDown}{ArrowDown}{/Shift}');
    // The card is already part of the selection, so clicking it node-selects it
    // without the selected flag ever flipping.
    await expect.poll(blockIsSelected).toBe(true);
    pretendToBeSafari();

    await userEvent.click(page.getByTestId('op-bn-work-package--type'));

    await expect.poll(blockIsSelected).toBe(true);
    await expect.poll(nativeSelectionIsCollapsed).toBe(true);
  });

  it('leaves a text selection spanning the card alone', async () => {
    renderEditor();
    const editorEl = page.getByRole('textbox');
    await userEvent.click(editorEl);
    await userEvent.keyboard('above{Enter}');
    await insertBlockWorkPackageViaSlashMenu();
    await userEvent.keyboard('{Enter}below');
    pretendToBeSafari();

    await userEvent.click(page.getByText('above'));
    await userEvent.keyboard('{Home}');
    await userEvent.keyboard('{Shift>}{ArrowDown}{ArrowDown}{ArrowDown}{/Shift}');

    await expect.poll(blockIsSelected).toBe(true);
    await afterCollapseFrame();
    expect(nativeSelectionIsCollapsed()).toBe(false);
  });

  it('leaves a node selection on a foreign node type alone', async () => {
    let renderedEditor:AnyEditor | undefined;
    renderEditor({ onEditor: (created) => { renderedEditor = created; } });
    await insertBlockWorkPackageViaSlashMenu();
    await expect.element(page.getByTestId('block-wp-wrapper')).toBeVisible();

    const editor = renderedEditor!;
    editor.insertBlocks([{ type: 'divider' }], editor.document[0], 'after');
    const view = editor.prosemirrorView;
    let dividerPosition = -1;
    view.state.doc.descendants((node, position) => {
      if (node.type.name === 'divider') dividerPosition = position;
      return dividerPosition === -1;
    });
    view.dispatch(view.state.tr.setSelection(NodeSelection.create(view.state.doc, dividerPosition)));
    pretendToBeSafari();

    hideSafariPhantomSelection(editor);

    await afterCollapseFrame();
    expect(nativeSelectionIsCollapsed()).toBe(false);
  });

  it('does nothing outside Safari', async () => {
    renderEditor();
    await insertBlockWorkPackageViaSlashMenu();
    await expect.element(page.getByTestId('block-wp-wrapper')).toBeVisible();
    pretendNotToBeSafari();

    await userEvent.click(page.getByTestId('op-bn-work-package--type'));

    await expect.poll(blockIsSelected).toBe(true);
    await afterCollapseFrame();
    expect(nativeSelectionIsCollapsed()).toBe(false);
  });
});
