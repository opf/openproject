import { describe, it, expect, vi } from 'vitest';
import { render } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { WpOptionsPopover } from '../../../../lib/components/WorkPackage/OptionsPopover';
import { mockWorkPackage } from '../../../mocks/handlers';
import type { WorkPackage } from '../../../../lib/openProjectTypes';

const wp = mockWorkPackage as unknown as WorkPackage;

type PopoverProps = Partial<React.ComponentProps<typeof WpOptionsPopover>>;

function renderInlinePopover(props: PopoverProps = {}) {
  return render(
    <div style={{ position: 'relative', marginTop: '80px', display: 'inline-block' }}>
      <WpOptionsPopover
        wp={wp}
        currentSize="s"
        instanceId="test-instance"
        onClose={vi.fn()}
        onResize={vi.fn()}
        onRemove={vi.fn()}
        onConvertToBlock={vi.fn()}
        {...props}
      />
    </div>
  );
}

function renderBlockPopover(props: PopoverProps = {}) {
  return render(
    <div style={{ position: 'relative', marginTop: '80px', display: 'inline-block' }}>
      <WpOptionsPopover
        wp={wp}
        currentSize={undefined}
        currentBlockSize="m"
        instanceId={undefined}
        onClose={vi.fn()}
        onResizeBlock={vi.fn()}
        onConvertToInline={vi.fn()}
        onRemove={vi.fn()}
        {...props}
      />
    </div>
  );
}

describe('WpOptionsPopover - shared', () => {
  it('renders Open and Remove buttons in both modes', async () => {
    renderInlinePopover();
    await expect.element(page.getByTitle('Open in new tab')).toBeVisible();
    await expect.element(page.getByTitle('Remove')).toBeVisible();
  });

  it('opens work package in new tab on Open click', async () => {
    const openSpy = vi.spyOn(window, 'open').mockReturnValue(null);
    renderInlinePopover();

    await userEvent.click(page.getByTitle('Open in new tab'));

    expect(openSpy).toHaveBeenCalledOnce();
    expect(openSpy).toHaveBeenCalledWith(
      expect.stringContaining(`/wp/${wp.id}`),
      '_blank',
      'noopener,noreferrer'
    );
    openSpy.mockRestore();
  });

  it('calls onRemove and onClose when Remove is clicked', async () => {
    const onRemove = vi.fn();
    const onClose = vi.fn();
    renderInlinePopover({ onRemove, onClose });

    await userEvent.click(page.getByTitle('Remove'));

    expect(onRemove).toHaveBeenCalledOnce();
    expect(onClose).toHaveBeenCalledOnce();
  });

  it('hides the size menu after selecting any size', async () => {
    renderInlinePopover();

    await userEvent.click(page.getByTitle('Change size'));
    await expect.element(page.getByTestId('size-menu')).toBeVisible();

    await userEvent.click(page.getByRole('button', { name: 'Compact (inline)', exact: true }));
    await expect.element(page.getByTestId('size-menu')).not.toBeInTheDocument();
  });
});

describe('WpOptionsPopover — inline chip mode', () => {
  it('shows "Change size" button labelled with the current size', async () => {
    renderInlinePopover({ currentSize: 's' });
    const btn = page.getByTitle('Change size');
    await expect.element(btn).toBeVisible();
    await expect.element(btn).toHaveTextContent('Regular (inline)');
  });

  it('shows all 6 size options', async () => {
    renderInlinePopover();

    await userEvent.click(page.getByTitle('Change size'));

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

  it('highlights the currently active inline size', async () => {
    renderInlinePopover({ currentSize: 'xs' });

    await userEvent.click(page.getByTitle('Change size'));

    await expect.element(page.getByRole('button', { name: 'Compact (inline)', exact: true })).toBeVisible();
  });

  it('calls onResize with "xxs" when Tiny (inline) is selected', async () => {
    const onResize = vi.fn();
    const onClose = vi.fn();
    renderInlinePopover({ onResize, onClose });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Tiny (inline)', exact: true }));

    expect(onResize).toHaveBeenCalledWith('xxs');
    expect(onClose).toHaveBeenCalledOnce();
  });

  it('calls onResize with "xs" when Compact (inline) is selected', async () => {
    const onResize = vi.fn();
    renderInlinePopover({ onResize });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Compact (inline)', exact: true }));

    expect(onResize).toHaveBeenCalledWith('xs');
  });

  it('calls onResize with "s" when Regular (inline) is selected', async () => {
    const onResize = vi.fn();
    renderInlinePopover({ currentSize: 'xxs', onResize });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Regular (inline)', exact: true }));

    expect(onResize).toHaveBeenCalledWith('s');
  });

  it('calls onConvertToBlock with "m" when Compact card is selected', async () => {
    const onConvertToBlock = vi.fn();
    renderInlinePopover({ onConvertToBlock });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Compact card', exact: true }));

    expect(onConvertToBlock).toHaveBeenCalledWith('m');
  });

  it('calls onConvertToBlock with "l" when Regular card is selected', async () => {
    const onConvertToBlock = vi.fn();
    renderInlinePopover({ onConvertToBlock });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Regular card', exact: true }));

    expect(onConvertToBlock).toHaveBeenCalledWith('l');
  });

  it('calls onConvertToBlock with "xl" when Full card is selected', async () => {
    const onConvertToBlock = vi.fn();
    renderInlinePopover({ onConvertToBlock });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Full card', exact: true }));

    expect(onConvertToBlock).toHaveBeenCalledWith('xl');
  });
});

describe('WpOptionsPopover - block card mode', () => {
  it('shows "Change size" button labelled with the current block size', async () => {
    renderBlockPopover({ currentBlockSize: 'l' });
    const btn = page.getByTitle('Change size');
    await expect.element(btn).toBeVisible();
    await expect.element(btn).toHaveTextContent('Regular card');
  });

  it('shows block size section (Compact card / Regular card / Full card) and inline conversion section (Tiny / Compact / Regular)', async () => {
    renderBlockPopover();

    await userEvent.click(page.getByTitle('Change size'));

    for (const label of [
      'Compact card',
      'Regular card',
      'Full card',
      'Tiny (inline)',
      'Compact (inline)',
      'Regular (inline)',
    ]) {
      await expect.element(page.getByRole('button', { name: label, exact: true })).toBeVisible();
    }
  });

  it('shows "Block size" and "Convert to inline" section labels', async () => {
    renderBlockPopover();

    await userEvent.click(page.getByTitle('Change size'));

    await expect.element(page.getByText('Block size')).toBeVisible();
    await expect.element(page.getByText('Convert to inline')).toBeVisible();
  });

  it('highlights the currently active block size', async () => {
    renderBlockPopover({ currentBlockSize: 'l' });

    await userEvent.click(page.getByTitle('Change size'));

    await expect.element(page.getByRole('button', { name: 'Regular card', exact: true })).toBeVisible();
  });

  it('calls onResizeBlock with "m" when Compact card is selected', async () => {
    const onResizeBlock = vi.fn();
    const onClose = vi.fn();
    renderBlockPopover({ currentBlockSize: 'l', onResizeBlock, onClose });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Compact card', exact: true }));

    expect(onResizeBlock).toHaveBeenCalledWith('m');
    expect(onClose).toHaveBeenCalledOnce();
  });

  it('calls onResizeBlock with "l" when Regular card is selected', async () => {
    const onResizeBlock = vi.fn();
    renderBlockPopover({ currentBlockSize: 'm', onResizeBlock });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Regular card', exact: true }));

    expect(onResizeBlock).toHaveBeenCalledWith('l');
  });

  it('calls onResizeBlock with "xl" when Full card is selected', async () => {
    const onResizeBlock = vi.fn();
    renderBlockPopover({ onResizeBlock });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Full card', exact: true }));

    expect(onResizeBlock).toHaveBeenCalledWith('xl');
  });

  it('calls onConvertToInline with "xxs" when Tiny (inline) is selected', async () => {
    const onConvertToInline = vi.fn();
    const onClose = vi.fn();
    renderBlockPopover({ onConvertToInline, onClose });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Tiny (inline)', exact: true }));

    expect(onConvertToInline).toHaveBeenCalledWith('xxs');
    expect(onClose).toHaveBeenCalledOnce();
  });

  it('calls onConvertToInline with "xs" when Compact (inline) is selected', async () => {
    const onConvertToInline = vi.fn();
    renderBlockPopover({ onConvertToInline });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Compact (inline)', exact: true }));

    expect(onConvertToInline).toHaveBeenCalledWith('xs');
  });

  it('calls onConvertToInline with "s" when Regular (inline) is selected', async () => {
    const onConvertToInline = vi.fn();
    renderBlockPopover({ onConvertToInline });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'Regular (inline)', exact: true }));

    expect(onConvertToInline).toHaveBeenCalledWith('s');
  });
});