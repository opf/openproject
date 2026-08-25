import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { render } from 'vitest-browser-react';
import { useState } from 'react';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertInlineWorkPackageViaSlashMenu,
  insertInlineWorkPackageViaHash,
  openInlineWorkPackagePopover,
} from '../../../helpers/editorHelpers';
import { WpPreviewPopover } from '../../../../lib/components/WorkPackage/PreviewPopover';
import { BlockCard } from '../../../../lib/components/BlockWorkPackage/BlockCard';
import type { WorkPackage } from '../../../../lib/openProjectTypes';

const wait = (ms:number) => new Promise((resolve) => setTimeout(resolve, ms));

const chipElement = () => page.getByText('#123').first().element().closest('.op-bn-inline-wp')!;

type PointerEventType = 'pointerdown' | 'pointerup' | 'pointermove' | 'pointercancel';

const dispatchPointer = (chip:Element, type:PointerEventType, init:PointerEventInit = {}) =>
  chip.dispatchEvent(new PointerEvent(type, { bubbles: true, ...init }));

const dragStartPrevented = (chip:Element) => {
  const dragStart = new DragEvent('dragstart', { bubbles: true, cancelable: true });
  chip.dispatchEvent(dragStart);
  return dragStart.defaultPrevented;
};

const previewWp:WorkPackage = {
  id: 123,
  displayId: '123',
  subject: 'Fix login bug',
  _links: {
    self: { href: '/api/v3/work_packages/123' },
    type: { title: 'Bug', href: '/api/v3/types/1' },
    status: { title: 'In Progress', href: '/api/v3/statuses/1' },
    assignee: null,
  },
};

// Renders the preview against a fixed anchor so the flip behaviour can be
// asserted for anchors near the viewport edges.
function FlipHarness({ anchorTop }:{ anchorTop:number }) {
  const [anchor, setAnchor] = useState<HTMLElement | null>(null);
  return (
    <div>
      <span
        ref={setAnchor}
        data-testid="flip-anchor"
        style={{ position: 'fixed', top: anchorTop, left: 40 }}
      >
        #123
      </span>
      {anchor && (
        <WpPreviewPopover anchorEl={anchor}>
          <BlockCard workPackage={previewWp} size="m" linkTitle />
        </WpPreviewPopover>
      )}
    </div>
  );
}

describe('Inline chip - XXS hover preview', () => {
  it('shows no preview before hovering', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');

    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });

  it('hovering an XXS chip shows a card preview with type, status and subject', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');

    await userEvent.hover(page.getByText('#123').first());

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('moving the pointer away hides the preview', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');

    await userEvent.hover(page.getByText('#123').first());
    await expect.element(page.getByTestId('wp-preview')).toBeVisible();

    await userEvent.unhover(page.getByText('#123').first());
    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });

  it('clicking the chip opens the options popover and hides the hover preview', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');

    await userEvent.hover(page.getByText('#123').first());
    await expect.element(page.getByTestId('wp-preview')).toBeVisible();

    await openInlineWorkPackagePopover();

    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });

  it('does not re-show the preview when hovering the chip while the options menu is open', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');

    await openInlineWorkPackagePopover();
    await expect.element(page.getByTestId('popover-content')).toBeVisible();

    await userEvent.hover(page.getByText('#123').first());
    await wait(600);

    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
  });

  it('does not show a preview when hovering an S chip', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    await userEvent.hover(page.getByText('#123').first());

    // Give the open delay a chance to elapse before asserting absence
    await wait(600);
    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });
});

describe('Inline chip - XXS long-press preview (touch)', () => {
  // The chip reads (hover: hover) once per mount, so touch has to be faked before rendering.
  beforeEach(() => {
    vi.stubGlobal('matchMedia', (query:string) => ({
      matches: false,
      media: query,
      onchange: null,
      addEventListener: () => {},
      removeEventListener: () => {},
      addListener: () => {},
      removeListener: () => {},
      dispatchEvent: () => false,
    }));
  });

  afterEach(() => vi.unstubAllGlobals());

  async function renderChip() {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');
    // let the fetch settle so the chip's remount doesn't clear the long-press timer
    await wait(600);
    return chipElement();
  }

  it('opens the preview on a long press and not on a quick tap', async () => {
    const chip = await renderChip();

    dispatchPointer(chip, 'pointerdown');
    dispatchPointer(chip, 'pointerup');
    await wait(600);
    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();

    dispatchPointer(chip, 'pointerdown');
    await expect.element(page.getByTestId('wp-preview'), { timeout: 2000 }).toBeVisible();
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    // stays open after the finger lifts; only an outside tap closes it on touch
    dispatchPointer(chip, 'pointerup');
    await wait(300);
    await expect.element(page.getByTestId('wp-preview')).toBeVisible();
  });

  it('closes the preview when the user taps outside', async () => {
    const chip = await renderChip();

    dispatchPointer(chip, 'pointerdown');
    await expect.element(page.getByTestId('wp-preview'), { timeout: 2000 }).toBeVisible();

    document.body.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });

  it('cancels the long press when the finger moves past the tolerance', async () => {
    const chip = await renderChip();

    dispatchPointer(chip, 'pointerdown', { clientX: 100, clientY: 100 });
    dispatchPointer(chip, 'pointermove', { clientX: 100, clientY: 140 });
    await wait(600);

    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });

  // Blocking the lift would make the preview reliable too, but at the cost of dragging the
  // chip by touch - surviving the pointercancel it fires is what keeps both.
  it('leaves the native drag lift alone during a press', async () => {
    const chip = await renderChip();

    dispatchPointer(chip, 'pointerdown');

    expect(dragStartPrevented(chip)).toBe(false);
  });

  it('still opens the preview when another gesture cancels the pointer', async () => {
    const chip = await renderChip();

    dispatchPointer(chip, 'pointerdown');
    dispatchPointer(chip, 'pointercancel');

    await expect.element(page.getByTestId('wp-preview'), { timeout: 2000 }).toBeVisible();
  });

  it('does not open a spurious preview after a two-finger tap', async () => {
    const chip = await renderChip();

    // both fingers lift before the delay: the first timer must not be orphaned
    dispatchPointer(chip, 'pointerdown', { pointerId: 1 });
    dispatchPointer(chip, 'pointerdown', { pointerId: 2 });
    dispatchPointer(chip, 'pointerup', { pointerId: 1 });
    dispatchPointer(chip, 'pointerup', { pointerId: 2 });
    await wait(600);

    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });
});

describe('Preview popover - placement', () => {
  it('opens below the anchor when there is space', async () => {
    render(<FlipHarness anchorTop={50} />);

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();

    const anchorRect = page.getByTestId('flip-anchor').element().getBoundingClientRect();
    const previewRect = page.getByTestId('wp-preview').element().getBoundingClientRect();
    expect(previewRect.top).toBeGreaterThanOrEqual(anchorRect.bottom);
  });

  it('flips above the anchor near the bottom of the viewport', async () => {
    render(<FlipHarness anchorTop={window.innerHeight - 30} />);

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();

    const anchorRect = page.getByTestId('flip-anchor').element().getBoundingClientRect();
    const previewRect = page.getByTestId('wp-preview').element().getBoundingClientRect();
    expect(previewRect.bottom).toBeLessThanOrEqual(anchorRect.top);
    expect(previewRect.top).toBeGreaterThanOrEqual(0);
  });
});
