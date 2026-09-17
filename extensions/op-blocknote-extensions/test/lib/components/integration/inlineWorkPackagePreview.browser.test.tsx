import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { render } from 'vitest-browser-react';
import { useState } from 'react';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertInlineWorkPackageViaSlashMenu,
  insertInlineWorkPackageViaHash,
  openInlineWorkPackagePopover,
  tapElement,
} from '../../../helpers/editorHelpers';
import { WpPreviewPopover } from '../../../../lib/components/WorkPackage/PreviewPopover';
import { BlockCard } from '../../../../lib/components/BlockWorkPackage/BlockCard';
import type { WorkPackage } from '../../../../lib/openProjectTypes';

const wait = (ms:number) => new Promise((resolve) => setTimeout(resolve, ms));

const chipElement = () => page.getByText('#123').first().element().closest('.op-bn-inline-wp')!;

const indicator = () => page.getByTestId('wp-preview-indicator');

const pressChip = (chip:Element) =>
  chip.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));

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

// Renders the preview against a fixed anchor so placement and layout can be
// asserted without going through the editor.
function PreviewHarness({ anchorTop, workPackage = previewWp }:{ anchorTop:number; workPackage?:WorkPackage }) {
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
          <BlockCard workPackage={workPackage} size="m" linkTitle />
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

describe('Inline chip - XXS preview indicator (touch)', () => {
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
    await expect.element(indicator()).toBeVisible();
  }

  it('renders the indicator inside the chip pill', async () => {
    await renderChip();

    const pill = chipElement().querySelector('.op-bn-inline-wp-base')!;
    expect(pill.contains(indicator().element())).toBe(true);
    expect(indicator().element().getAttribute('aria-label')).toBe('Show details of work package #123');
  });

  it('tapping the indicator opens the preview', async () => {
    await renderChip();

    await userEvent.click(indicator());

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(indicator()).toHaveAttribute('aria-expanded', 'true');
  });

  it('tapping the indicator again closes the preview', async () => {
    await renderChip();

    await userEvent.click(indicator());
    await expect.element(page.getByTestId('wp-preview')).toBeVisible();

    await userEvent.click(indicator());
    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });

  it('opens the preview from the keyboard', async () => {
    await renderChip();

    indicator().element().focus();
    await userEvent.keyboard('{Enter}');

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();
  });

  it('tapping the chip beside the indicator opens the options popover, not the preview', async () => {
    await renderChip();

    await openInlineWorkPackagePopover();

    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });

  it('tapping the indicator while the options popover is open swaps it for the preview', async () => {
    await renderChip();

    await openInlineWorkPackagePopover();
    await userEvent.click(indicator());

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();
    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
  });

  it('opens the preview from a touch that never becomes a click', async () => {
    await renderChip();

    tapElement(indicator().element());

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();
    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
  });

  it('closes the preview with a second such touch', async () => {
    await renderChip();

    tapElement(indicator().element());
    await expect.element(page.getByTestId('wp-preview')).toBeVisible();

    tapElement(indicator().element());
    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });

  it("centres the icon on the identifier's capital letters", async () => {
    await renderChip();

    const id = chipElement().querySelector('.op-bn-work-package--id')!;
    const probe = document.createElement('span');
    probe.style.cssText = 'display:inline-block;width:0;height:1cap';
    id.appendChild(probe);
    const capBox = probe.getBoundingClientRect();
    probe.remove();

    const icon = indicator().element().querySelector('svg')!.getBoundingClientRect();
    const drift = (icon.top + icon.bottom) / 2 - (capBox.top + capBox.bottom) / 2;
    expect(Math.abs(drift)).toBeLessThan(0.5);
    expect(icon.height).toBeGreaterThan(capBox.height);
    expect(icon.height).toBeLessThan(capBox.height * 1.3);
  });

  it('exposes the chip and the indicator as two separate buttons', async () => {
    await renderChip();

    expect(chipElement().getAttribute('role')).toBeNull();
    expect(indicator().element().tagName).toBe('BUTTON');

    const id = page.getByText('#123').first().element();
    expect(id.getAttribute('role')).toBe('button');
    expect(id.getAttribute('aria-label')).toBe('Work package #123');
  });

  it('opens the options popover from the id with the keyboard', async () => {
    await renderChip();

    page.getByText('#123').first().element()
      .dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));

    await expect.element(page.getByTestId('popover-content')).toBeVisible();
  });

  it('closes the preview when the user taps outside', async () => {
    await renderChip();

    await userEvent.click(indicator());
    await expect.element(page.getByTestId('wp-preview')).toBeVisible();

    document.body.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });

  it('does not open a preview on a long press', async () => {
    await renderChip();

    pressChip(chipElement());
    await wait(800);

    await expect.element(page.getByTestId('wp-preview')).not.toBeInTheDocument();
  });

  it('leaves the touch gesture to the browser so native selection still works', async () => {
    await renderChip();

    expect(getComputedStyle(chipElement()).touchAction).not.toBe('none');
  });

  it('shows no indicator on an S chip', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(indicator()).not.toBeInTheDocument();
  });
});

describe('Inline chip - XXS preview indicator (hover devices)', () => {
  it('shows no indicator when the pointer can hover', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');

    await expect.element(page.getByText('#123').first()).toBeVisible();
    await expect.element(indicator()).not.toBeInTheDocument();
  });
});

describe('Preview popover - placement', () => {
  it('opens below the anchor when there is space', async () => {
    render(<PreviewHarness anchorTop={50} />);

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();

    const anchorRect = page.getByTestId('flip-anchor').element().getBoundingClientRect();
    const previewRect = page.getByTestId('wp-preview').element().getBoundingClientRect();
    expect(previewRect.top).toBeGreaterThanOrEqual(anchorRect.bottom);
  });

  it('flips above the anchor near the bottom of the viewport', async () => {
    render(<PreviewHarness anchorTop={window.innerHeight - 30} />);

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();

    const anchorRect = page.getByTestId('flip-anchor').element().getBoundingClientRect();
    const previewRect = page.getByTestId('wp-preview').element().getBoundingClientRect();
    expect(previewRect.bottom).toBeLessThanOrEqual(anchorRect.top);
    expect(previewRect.top).toBeGreaterThanOrEqual(0);
  });
});

describe('Preview popover - long work package type', () => {
  const longType = 'CECILE CONFIGURATION FORM TEST TYPE AND SOME MORE WORDS SO THE TYPE GETS LONG';
  const longTypeWp:WorkPackage = {
    ...previewWp,
    _links: { ...previewWp._links!, type: { title: longType, href: '/api/v3/types/1' } },
  };

  it('wraps a long type instead of overflowing the preview', async () => {
    render(<PreviewHarness anchorTop={50} workPackage={longTypeWp} />);

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();
    // Shown in full: the type wraps onto more lines, it is never truncated.
    await expect.element(page.getByText(longType)).toBeVisible();

    const previewElement = page.getByTestId('wp-preview').element();
    const typeRect = page.getByTestId('op-bn-work-package--type').element().getBoundingClientRect();
    expect(typeRect.right).toBeLessThanOrEqual(previewElement.getBoundingClientRect().right);
    // scrollWidth > clientWidth means content sticks out to the right of the preview.
    expect(previewElement.scrollWidth).toBeLessThanOrEqual(previewElement.clientWidth);
  });

  it('continues the meta line after a wrapped type instead of breaking to a new one', async () => {
    render(<PreviewHarness anchorTop={50} workPackage={longTypeWp} />);

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();

    const previewElement = page.getByTestId('wp-preview').element();
    const typeRect = page.getByTestId('op-bn-work-package--type').element().getBoundingClientRect();
    const idRect = previewElement.querySelector('.op-bn-work-package--id')!.getBoundingClientRect();

    expect(idRect.top).toBeLessThan(typeRect.bottom);
    expect(idRect.left).toBeGreaterThan(typeRect.left);
  });
});
