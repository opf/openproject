import { describe, it, expect, vi, beforeEach, onTestFinished } from 'vitest';
import { render } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { WorkPackageSearchPopover } from '../../../../lib/components/Search/WorkPackageSearchPopover';
import { renderEditor } from '../../../helpers/renderEditor';
import { SEARCH_PLACEHOLDER, openBlockWorkPackageSearch } from '../../../helpers/editorHelpers';

const GAP_FROM_EDGE = 40;
const NEAR_ANCHOR = 40;

const searchPopover = () => document.querySelector<HTMLElement>('.op-bn-search')!;
const searchInput = () => document.querySelector<HTMLElement>('.op-bn-search input')!;
const resultList = () => document.querySelector<HTMLElement>('.op-bn-search [role="listbox"]')!;

const searchForAResult = async () => {
  await userEvent.type(page.getByPlaceholder(SEARCH_PLACEHOLDER), 'Fix');
  await expect.element(page.getByText('Fix login bug')).toBeVisible();
};

const renderPopoverAnchoredAt = async (top:number) => {
  const anchor = document.createElement('div');
  anchor.style.cssText = `position: absolute; left: 20px; top: ${top}px; width: 200px; height: 20px;`;
  document.body.append(anchor);
  onTestFinished(() => anchor.remove());

  render(<WorkPackageSearchPopover anchorEl={anchor} onSelect={vi.fn()} onCancel={vi.fn()} />);
  await expect.element(page.getByPlaceholder(SEARCH_PLACEHOLDER)).toBeVisible();

  return anchor;
};

const scrollToViewportBottom = (element:Element) => {
  const spacer = document.createElement('div');
  spacer.style.height = `${window.innerHeight}px`;
  document.body.prepend(spacer);
  onTestFinished(() => {
    spacer.remove();
    window.scrollTo(0, 0);
  });

  window.scrollBy(0, element.getBoundingClientRect().top - (window.innerHeight - GAP_FROM_EDGE));
};

describe('Work package search popover placement', () => {
  beforeEach(() => window.scrollTo(0, 0));

  it('opens below its anchor while there is room for it', async () => {
    const anchor = await renderPopoverAnchoredAt(GAP_FROM_EDGE);

    expect(searchPopover().getBoundingClientRect().top)
      .toBeGreaterThanOrEqual(anchor.getBoundingClientRect().bottom);
  });

  it('flips above its anchor when the anchor sits at the bottom edge', async () => {
    const anchor = await renderPopoverAnchoredAt(window.innerHeight - GAP_FROM_EDGE);

    const popoverRect = searchPopover().getBoundingClientRect();
    expect(popoverRect.bottom).toBeLessThanOrEqual(anchor.getBoundingClientRect().top);
  });

  it('lists the results below the input while the popover opens downwards', async () => {
    await renderPopoverAnchoredAt(GAP_FROM_EDGE);
    await searchForAResult();

    expect(searchInput().getBoundingClientRect().bottom)
      .toBeLessThanOrEqual(resultList().getBoundingClientRect().top);
  });

  it('grows the results upwards and leaves the input at the anchor when flipped', async () => {
    const anchor = await renderPopoverAnchoredAt(window.innerHeight - GAP_FROM_EDGE);
    await searchForAResult();

    const inputRect = searchInput().getBoundingClientRect();
    const gapToAnchor = anchor.getBoundingClientRect().top - inputRect.bottom;
    expect(resultList().getBoundingClientRect().bottom).toBeLessThanOrEqual(inputRect.top);
    expect(gapToAnchor).toBeGreaterThanOrEqual(0);
    expect(gapToAnchor).toBeLessThan(NEAR_ANCHOR);
  });

  it('opens the block search popover above a block at the bottom of the page', async () => {
    renderEditor();
    await expect.element(page.getByRole('textbox')).toBeVisible();
    scrollToViewportBottom(document.querySelector('.bn-editor')!);

    await openBlockWorkPackageSearch();

    const blockRect = document.querySelector('[data-testid="block-wp-wrapper"]')!.getBoundingClientRect();
    expect(blockRect.top).toBeGreaterThan(window.innerHeight - GAP_FROM_EDGE * 2);

    const popoverRect = searchPopover().getBoundingClientRect();
    expect(popoverRect.bottom).toBeLessThanOrEqual(blockRect.top);
    expect(popoverRect.top).toBeGreaterThanOrEqual(0);
  });
});
