import { describe, it, expect } from 'vitest';
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
        <WpPreviewPopover anchorEl={anchor} onClose={() => {}}>
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
    await new Promise((resolve) => setTimeout(resolve, 600));

    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
  });

  it('does not show a preview when hovering an S chip', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    await userEvent.hover(page.getByText('#123').first());

    // Give the open delay a chance to elapse before asserting absence
    await new Promise((resolve) => setTimeout(resolve, 600));
    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });
});

describe('Inline chip - XXS long-press preview (touch)', () => {
  function forceTouch() {
    const original = window.matchMedia;
    window.matchMedia = ((query:string) => ({
      matches: false,
      media: query,
      onchange: null,
      addEventListener: () => {},
      removeEventListener: () => {},
      addListener: () => {},
      removeListener: () => {},
      dispatchEvent: () => false,
    })) as typeof window.matchMedia;
    return () => { window.matchMedia = original; };
  }

  it('opens the preview on a long press and not on a quick tap', async () => {
    const restore = forceTouch();
    try {
      renderEditor();
      await insertInlineWorkPackageViaHash('#');
      // let the fetch settle so the chip's remount doesn't clear the long-press timer
      await new Promise((resolve) => setTimeout(resolve, 600));

      const chip = page.getByText('#123').first().element().closest('.op-bn-inline-wp')!;

      chip.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
      chip.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));
      await new Promise((resolve) => setTimeout(resolve, 600));
      await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();

      chip.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
      await expect.element(page.getByTestId('wp-preview'), { timeout: 2000 }).toBeVisible();
      await expect.element(page.getByTestId('block-card')).toBeVisible();

      // stays open after the finger lifts; only an outside tap closes it on touch
      chip.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));
      await new Promise((resolve) => setTimeout(resolve, 300));
      await expect.element(page.getByTestId('wp-preview')).toBeVisible();
    }
    finally {
      restore();
    }
  });

  it('closes the preview when the user taps outside', async () => {
    const restore = forceTouch();
    try {
      renderEditor();
      await insertInlineWorkPackageViaHash('#');
      // let the fetch settle so the chip's remount doesn't clear the long-press timer
      await new Promise((resolve) => setTimeout(resolve, 600));

      const chip = page.getByText('#123').first().element().closest('.op-bn-inline-wp')!;

      chip.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
      await expect.element(page.getByTestId('wp-preview'), { timeout: 2000 }).toBeVisible();

      document.body.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
      await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
    }
    finally {
      restore();
    }
  });

  it('cancels the long press when the finger moves past the tolerance', async () => {
    const restore = forceTouch();
    try {
      renderEditor();
      await insertInlineWorkPackageViaHash('#');
      // let the fetch settle so the chip's remount doesn't clear the long-press timer
      await new Promise((resolve) => setTimeout(resolve, 600));

      const chip = page.getByText('#123').first().element().closest('.op-bn-inline-wp')!;

      chip.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, clientX: 100, clientY: 100 }));
      chip.dispatchEvent(new PointerEvent('pointermove', { bubbles: true, clientX: 100, clientY: 140 }));
      await new Promise((resolve) => setTimeout(resolve, 600));

      await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
    }
    finally {
      restore();
    }
  });

  it('does not open a spurious preview after a two-finger tap', async () => {
    const restore = forceTouch();
    try {
      renderEditor();
      await insertInlineWorkPackageViaHash('#');
      // let the fetch settle so the chip's remount doesn't clear the long-press timer
      await new Promise((resolve) => setTimeout(resolve, 600));

      const chip = page.getByText('#123').first().element().closest('.op-bn-inline-wp')!;

      // both fingers lift before the delay: the first timer must not be orphaned
      chip.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, pointerId: 1 }));
      chip.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true, pointerId: 2 }));
      chip.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, pointerId: 1 }));
      chip.dispatchEvent(new PointerEvent('pointerup', { bubbles: true, pointerId: 2 }));
      await new Promise((resolve) => setTimeout(resolve, 600));

      await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
    }
    finally {
      restore();
    }
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
