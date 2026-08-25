import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, cleanup } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { useState, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { InlineWorkPackageChip } from '../../../../lib/components/InlineWorkPackage/InlineWorkPackageChip';
import { ShadowDomWrapper } from '../../../../lib/components/ShadowDomWrapper';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertInlineWorkPackageViaSlashMenu,
  openInlineWorkPackagePopover,
  openBlockCardPopover,
  convertToCompactCard,
} from '../../../helpers/editorHelpers';

afterEach(() => {
  cleanup();
});

// BlockNote leaves an empty display:none toolbar container in the DOM when
// closed, so presence alone is not enough - only a rendered one counts.
const formattingToolbarVisible = () =>
  Array.from(document.querySelectorAll('[class*="formatting-toolbar"]')).some((el) => {
    const he = el as HTMLElement;
    return getComputedStyle(he).display !== 'none' && he.childElementCount > 0;
  });

function ChipWrapper({ initialSize, wpid = '123' }:{
  initialSize:string;
  wpid?:string;
}) {
  const [size, setSize] = useState(initialSize);

  return (
    <div style={{ paddingTop: '200px', paddingLeft: '20px' }}>
      <InlineWorkPackageChip
        inlineContent={{ props: { wpid, size, displayId: wpid } }}
        contentRef={vi.fn()}
        updateInlineContent={(update) => setSize(update.props.size)}
      />
    </div>
  );
}

async function waitForResolvedChip() {
  await expect.element(page.getByText('#123')).toBeVisible();
}

async function openPopover() {
  await userEvent.click(page.getByText('#123'));
  await expect.element(page.getByTestId('popover-content')).toBeVisible();
}

const getPopover = (root:ParentNode = document):Element =>
  root.querySelector('[data-testid="popover-content"]')!;

const getScrollerRect = ():DOMRect =>
  page.getByTestId('scroller').element().getBoundingClientRect();

async function openSizeMenu() {
  await openPopover();
  await userEvent.click(page.getByTitle('Change size'));
  await expect.element(page.getByTestId('size-menu')).toBeVisible();
}

describe('Inline chip size transitions (user-visible content)', () => {
  it('switching from XXS to XS reveals the type badge and subject', async () => {
    render(<ChipWrapper initialSize="xxs" />);
    await waitForResolvedChip();

    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
    await expect.element(page.getByText('Fix login bug')).not.toBeInTheDocument();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();

    await openSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Compact', exact: true }));

    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
  });

  it('switching from XS to S reveals the status badge', async () => {
    render(<ChipWrapper initialSize="xs" />);
    await waitForResolvedChip();

    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();

    await openSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Regular', exact: true }));

    await expect.element(page.getByText('In Progress')).toBeVisible();
  });

  it('switching from S back to XXS hides the type, status, and subject', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();

    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();

    await openSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Tiny', exact: true }));

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
    await expect.element(page.getByText('Fix login bug')).not.toBeInTheDocument();
  });

  it('removing a chip deletes it from the document and closes the popover', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await openInlineWorkPackagePopover();

    await userEvent.click(page.getByTitle('Remove'));

    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
    await expect.element(page.getByText('#123')).not.toBeInTheDocument();
  });
});

describe('Options popover portal', () => {
  it('inline chip: popover is rendered outside the chip DOM so it is not clipped by overflow', async () => {
    render(
      <div data-testid="chip-wrapper">
        <InlineWorkPackageChip
          inlineContent={{ props: { wpid: '123', size: 's', displayId: '123' } }}
          contentRef={vi.fn()}
        />
      </div>,
    );

    await waitForResolvedChip();
    await openPopover();

    const chipWrapper = document.querySelector('[data-testid="chip-wrapper"]');
    const popoverInsideWrapper = chipWrapper?.querySelector('[data-testid="popover-content"]');
    expect(popoverInsideWrapper).toBeNull();

    const popoverInDocument = document.querySelector('[data-testid="popover-content"]');
    expect(popoverInDocument).not.toBeNull();
  });

  it('block card: popover is rendered outside the block DOM so it is not clipped by overflow', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardPopover();

    const blockEl = document.querySelector('[data-content-type="openProjectWorkPackageBlock"]');
    const popoverInsideBlock = blockEl?.querySelector('[data-testid="popover-content"]');
    expect(popoverInsideBlock).toBeNull();

    const popoverInDocument = document.querySelector('[data-testid="popover-content"]');
    expect(popoverInDocument).not.toBeNull();
  });
});

describe('Options popover positioning', () => {
  it('opens at the start of a chip that wraps across multiple lines', async () => {
    render(
      <div style={{ width: '140px', paddingTop: '200px' }}>
        <span style={{ display: 'inline-block', width: '90px' }} />
        <InlineWorkPackageChip
          inlineContent={{ props: { wpid: '123', size: 's', displayId: '123' } }}
          contentRef={vi.fn()}
        />
      </div>,
    );

    await waitForResolvedChip();

    const chip = document.querySelector('.op-bn-inline-wp')!;
    const fragments = chip.getClientRects();
    expect(fragments.length).toBeGreaterThan(1);
    expect(fragments[0].left).toBeGreaterThan(chip.getBoundingClientRect().left);

    await openPopover();

    const popover = document.querySelector('[data-testid="popover-content"]')!;
    const popoverRect = popover.getBoundingClientRect();
    expect(popoverRect.left).toBeCloseTo(fragments[0].left, 0);
    expect(popoverRect.bottom).toBeLessThanOrEqual(fragments[0].top);
  });

  it('stays inside the viewport when the chip starts near the right edge', async () => {
    render(
      <div style={{ paddingTop: '200px' }}>
        <span style={{ display: 'inline-block', width: 'calc(100vw - 80px)' }} />
        <InlineWorkPackageChip
          inlineContent={{ props: { wpid: '123', size: 's', displayId: '123' } }}
          contentRef={vi.fn()}
        />
      </div>,
    );

    await waitForResolvedChip();

    const chip = document.querySelector('.op-bn-inline-wp')!;
    expect(chip.getClientRects()[0].left).toBeGreaterThan(window.innerWidth - 120);

    await openPopover();

    const popover = document.querySelector('[data-testid="popover-content"]')!;
    const popoverRect = popover.getBoundingClientRect();
    expect(popoverRect.right).toBeLessThanOrEqual(window.innerWidth);
    expect(popoverRect.left).toBeGreaterThanOrEqual(0);
  });
});

// Mirrors the OpenProject mobile layout: a page header above the container the
// document scrolls in.
function PageWithScroller({ height = 240, children }:{ height?:number; children:ReactNode }) {
  return (
    <div>
      <div data-testid="page-header" style={{ height: '60px', background: '#eee' }}>
        Header
      </div>
      <div data-testid="scroller" style={{ height: `${height}px`, overflowY: 'auto' }}>
        {children}
      </div>
    </div>
  );
}

function EditorContent({ chipOffset }:{ chipOffset:number }) {
  return (
    <div className="bn-container" style={{ position: 'relative' }}>
      <div style={{ paddingTop: `${chipOffset}px`, height: '900px' }}>
        <InlineWorkPackageChip
          inlineContent={{ props: { wpid: '123', size: 's', displayId: '123' } }}
          contentRef={vi.fn()}
        />
      </div>
    </div>
  );
}

function ScrollHarness({ chipOffset = 150, height = 240 }:{ chipOffset?:number; height?:number }) {
  return (
    <PageWithScroller height={height}>
      <EditorContent chipOffset={chipOffset} />
    </PageWithScroller>
  );
}

describe('Options popover while the document scrolls', () => {
  it('scrolls under the page header instead of hovering above it', async () => {
    render(<ScrollHarness />);
    await waitForResolvedChip();
    await openPopover();

    const scroller = page.getByTestId('scroller').element();
    const popover = getPopover();
    const scrollerTop = scroller.getBoundingClientRect().top;
    const popoverTopBefore = popover.getBoundingClientRect().top;
    expect(popoverTopBefore).toBeGreaterThan(scrollerTop);

    // Scroll just far enough that the popover reaches into the header's row.
    const delta = Math.round(popoverTopBefore - scrollerTop + 10);
    scroller.scrollTop = delta;
    await new Promise((resolve) => setTimeout(resolve, 100));

    const popoverRect = popover.getBoundingClientRect();
    expect(popoverRect.top).toBeCloseTo(popoverTopBefore - delta, 0);
    expect(popoverRect.top).toBeLessThan(scrollerTop);

    // The part reaching into the header row is clipped, not painted over it.
    const hitInHeaderRow = document.elementFromPoint(popoverRect.left + 4, scrollerTop - 4);
    expect(popover.contains(hitInHeaderRow)).toBe(false);
  });
});

// Same layout with the editor in a shadow root, as OpenProject mounts it.
function ShadowScrollHarness({ chipOffset }:{ chipOffset:number }) {
  const [shadowRoot, setShadowRoot] = useState<ShadowRoot | null>(null);
  const attachHost = (host:HTMLDivElement | null) => {
    if (host && !host.shadowRoot) setShadowRoot(host.attachShadow({ mode: 'open' }));
  };

  return (
    <PageWithScroller>
      <div ref={attachHost} data-testid="editor-host" />
      {shadowRoot && createPortal(
        <ShadowDomWrapper target={shadowRoot}>
          <EditorContent chipOffset={chipOffset} />
        </ShadowDomWrapper>,
        shadowRoot,
      )}
    </PageWithScroller>
  );
}

describe('Options popover on the first row', () => {
  it('stops at the page header edge instead of opening half hidden behind it', async () => {
    render(<ScrollHarness chipOffset={2} />);
    await waitForResolvedChip();
    await openPopover();

    const scrollerRect = getScrollerRect();
    const popoverRect = getPopover().getBoundingClientRect();

    expect(popoverRect.top).toBeGreaterThanOrEqual(scrollerRect.top);
    expect(popoverRect.bottom).toBeLessThanOrEqual(scrollerRect.bottom);
  });

  it('is parked inside the visible area when neither side of the chip has room', async () => {
    render(<ScrollHarness chipOffset={16} height={60} />);
    await waitForResolvedChip();
    await openPopover();

    const scrollerRect = getScrollerRect();
    const popoverRect = getPopover().getBoundingClientRect();

    expect(popoverRect.top).toBeGreaterThanOrEqual(scrollerRect.top);
    expect(popoverRect.bottom).toBeLessThanOrEqual(scrollerRect.bottom);
  });

  it('stays inside the scroll container when the editor is in a shadow root', async () => {
    render(<ShadowScrollHarness chipOffset={2} />);
    await waitForResolvedChip();
    await openPopover();

    const shadowRoot = page.getByTestId('editor-host').element().shadowRoot!;
    const scrollerRect = getScrollerRect();
    const popoverRect = getPopover(shadowRoot).getBoundingClientRect();

    expect(popoverRect.top).toBeGreaterThanOrEqual(scrollerRect.top);
    expect(popoverRect.bottom).toBeLessThanOrEqual(scrollerRect.bottom);
  });
});

describe('Inline chip popover UX', () => {
  it('popover is not visible before clicking the chip', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();
    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
  });

  it('clicking the chip opens the popover', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();
    await openPopover();
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
  });

  it('clicking the chip again closes the popover', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();
    await openPopover();

    await userEvent.click(page.getByText('#123'));
    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
  });

  it('clicking outside the chip closes the popover', async () => {
    render(
      <div style={{ paddingTop: '200px', paddingLeft: '20px' }}>
        <InlineWorkPackageChip
          inlineContent={{ props: { wpid: '123', size: 's', displayId: '123' } }}
          contentRef={vi.fn()}
        />
        <div data-testid="outside" style={{ marginTop: '20px' }}>Outside</div>
      </div>,
    );

    await waitForResolvedChip();
    await openPopover();
    await userEvent.click(page.getByTestId('outside'));
    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
  });

  it('"Open" button opens the work package in a new tab', async () => {
    const openSpy = vi.spyOn(window, 'open').mockReturnValue(null);
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();

    await openPopover();
    await userEvent.click(page.getByTitle('Open in new tab'));

    expect(openSpy).toHaveBeenCalledWith(
      expect.stringContaining('/wp/123'),
      '_blank',
      'noopener,noreferrer',
    );
    openSpy.mockRestore();
  });

  it('size menu is hidden before clicking the size button', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();
    await openPopover();
    await expect.element(page.getByTestId('size-menu')).not.toBeInTheDocument();
  });

  it('size menu appears after clicking the size button', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();
    await openSizeMenu();
    await expect.element(page.getByTestId('size-menu')).toBeVisible();
  });

  it('size menu closes after selecting a size', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();
    await openSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Compact', exact: true }));
    await expect.element(page.getByTestId('size-menu')).not.toBeInTheDocument();
  });

  it('size button label reflects the current chip size', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();
    await openPopover();
    await expect.element(page.getByTitle('Change size')).toHaveTextContent('Regular');
  });

  it('inline size menu shows all 6 options', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();
    await openSizeMenu();

    for (const label of [
      'Tiny',
      'Compact',
      'Regular',
      'Compact card',
    ]) {
      await expect.element(page.getByRole('button', { name: label, exact: true })).toBeVisible();
    }
  });
});

describe('Options popover coexists with the editor', () => {
  it('inline chip: opening the size menu summons no formatting toolbar', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await openInlineWorkPackagePopover();

    await userEvent.click(page.getByTitle('Change size'));

    await expect.element(page.getByTestId('size-menu')).toBeVisible();
    expect(formattingToolbarVisible()).toBe(false);
  });

  it('inline chip: resizing summons no formatting toolbar', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await openInlineWorkPackagePopover();
    await userEvent.click(page.getByTitle('Change size'));

    await userEvent.click(page.getByRole('button', { name: 'Compact', exact: true }));

    expect(formattingToolbarVisible()).toBe(false);
  });

  it('inline chip: a scroll keeps the popover anchored to the chip', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await openInlineWorkPackagePopover();

    const chip = document.querySelector('.op-bn-inline-wp')!;
    const popover = document.querySelector('[data-testid="popover-content"]')!;
    const distance = () =>
      chip.getBoundingClientRect().top - popover.getBoundingClientRect().top;
    const distanceBefore = distance();

    window.dispatchEvent(new Event('scroll'));
    await new Promise((resolve) => requestAnimationFrame(resolve));

    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    expect(distance()).toBeCloseTo(distanceBefore, 0);
  });

  it('block card: opening the popover summons no formatting toolbar', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardPopover();
    await expect.element(page.getByTestId('popover-content')).toBeVisible();

    expect(formattingToolbarVisible()).toBe(false);
  });
});