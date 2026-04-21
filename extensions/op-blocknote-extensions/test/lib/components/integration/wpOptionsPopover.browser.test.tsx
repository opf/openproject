import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, cleanup } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { useState, useEffect } from 'react';
import { InlineWorkPackageChip } from '../../../../lib/components/InlineWorkPackage/InlineWorkPackageChip';
import { wpBridge } from '../../../../lib/services/wpBridge';

afterEach(() => {
  cleanup();
});

function ChipWrapper({ initialSize, wpid = '123', instanceId = 'iid-test' }: {
  initialSize: string;
  wpid?: string;
  instanceId?: string;
}) {
  const [size, setSize] = useState(initialSize);

  useEffect(() => {
    const off = wpBridge.onResize(({ instanceId: iid, size: newSize }) => {
      if (iid === instanceId) setSize(newSize as string);
    });
    return off;
  }, [instanceId]);
  
  return (
    <div style={{ paddingTop: '200px', paddingLeft: '20px' }}>
      <InlineWorkPackageChip
        inlineContent={{ props: { wpid, size, instanceId } }}
        contentRef={vi.fn()}
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
    await userEvent.click(page.getByRole('button', { name: 'Compact (inline)', exact: true }));

    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
  });

  it('switching from XS to S reveals the status badge', async () => {
    render(<ChipWrapper initialSize="xs" />);
    await waitForResolvedChip();

    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();

    await openSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Regular (inline)', exact: true }));

    await expect.element(page.getByText('In Progress')).toBeVisible();
  });

  it('switching from S back to XXS hides the type, status, and subject', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();

    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();

    await openSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Tiny (inline)', exact: true }));

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
    await expect.element(page.getByText('Fix login bug')).not.toBeInTheDocument();
  });

  it('removing a chip closes the popover', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();
    await openPopover();

    let deleteWasCalled = false;
    const off = wpBridge.onDelete(() => { deleteWasCalled = true; });
    await userEvent.click(page.getByTitle('Remove'));
    off();

    expect(deleteWasCalled).toBe(true);
    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
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
          inlineContent={{ props: { wpid: '123', size: 's', instanceId: 'iid-outside' } }}
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
    await userEvent.click(page.getByRole('button', { name: 'Compact (inline)', exact: true }));
    await expect.element(page.getByTestId('size-menu')).not.toBeInTheDocument();
  });

  it('size button label reflects the current chip size', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();
    await openPopover();
    await expect.element(page.getByTitle('Change size')).toHaveTextContent('Regular (inline)');
  });

  it('inline size menu shows all 6 options', async () => {
    render(<ChipWrapper initialSize="s" />);
    await waitForResolvedChip();
    await openSizeMenu();

    for (const label of [
      'Tiny (inline)',
      'Compact (inline)',
      'Regular (inline)',
      'Compact card',
      'Regular card',
      'Full card',
    ]) {
      await expect.element(page.getByRole('button', { name: label, exact: true })).toBeVisible();
    }
  });
});