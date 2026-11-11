import { describe, it, expect, afterEach, vi } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { NodeSelection } from 'prosemirror-state';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertBlockWorkPackageViaSlashMenu,
  insertInlineWorkPackageViaSlashMenu,
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
