import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, cleanup } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { useState } from 'react';
import { InlineWorkPackageChip } from '../../../../lib/components/InlineWorkPackage/InlineWorkPackageChip';
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

  it('inline chip: a scroll closes the popover on desktop', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await openInlineWorkPackagePopover();

    window.dispatchEvent(new Event('scroll'));

    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
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