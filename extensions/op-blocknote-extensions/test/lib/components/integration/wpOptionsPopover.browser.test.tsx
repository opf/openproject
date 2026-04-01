import { describe, it, expect, vi } from 'vitest';
import { render } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { WpOptionsPopover } from '../../../../lib/components/WorkPackage/OptionsPopover';
import { mockWorkPackage } from '../../../mocks/handlers';
import type { WorkPackage } from '../../../../lib/openProjectTypes';

const wp = mockWorkPackage as unknown as WorkPackage;

function renderPopover(props: Partial<React.ComponentProps<typeof WpOptionsPopover>> = {}) {
  return render(
    <div style={{ position: 'relative', marginTop: '80px', display: 'inline-block' }}>
      <WpOptionsPopover
        wp={wp}
        currentSize="s"
        instanceId="test-instance"
        onClose={vi.fn()}
        onResize={vi.fn()}
        onRemove={vi.fn()}
        onConvertToInline={vi.fn()}
        {...props}
      />
    </div>
  );
}

describe('WpOptionsPopover', () => {
  it('renders Open, size, and Remove buttons', async () => {
    renderPopover();

    await expect.element(page.getByTitle('Open')).toBeVisible();
    await expect.element(page.getByTitle('Change size')).toBeVisible();
    await expect.element(page.getByTitle('Remove')).toBeVisible();
  });

  it('opens work package in new tab on Open click', async () => {
    const openSpy = vi.spyOn(window, 'open').mockReturnValue(null);
    renderPopover();

    await userEvent.click(page.getByTitle('Open'));

    expect(openSpy).toHaveBeenCalledOnce();
    expect(openSpy).toHaveBeenCalledWith(
      expect.stringContaining(`/wp/${wp.id}`),
      '_blank',
      'noopener,noreferrer'
    );
    openSpy.mockRestore();
  });

  it('calls onRemove when Remove is clicked', async () => {
    const onRemove = vi.fn();
    const onClose = vi.fn();
    renderPopover({ onRemove, onClose });

    await userEvent.click(page.getByTitle('Remove'));

    expect(onRemove).toHaveBeenCalledOnce();
    expect(onClose).toHaveBeenCalledOnce();
  });

  it('shows size menu when size button is clicked', async () => {
    renderPopover();

    await userEvent.click(page.getByTitle('Change size'));

    await expect.element(page.getByTestId('size-menu')).toBeVisible();
    await expect.element(page.getByRole('button', { name: 'XXS' })).toBeVisible();
    await expect.element(page.getByRole('button', { name: 'XS', exact: true })).toBeVisible();
    await expect.element(page.getByRole('button', { name: 'S', exact: true })).toBeVisible();
  });

  it('calls onResize and onClose when a size is selected', async () => {
    const onResize = vi.fn();
    const onClose = vi.fn();
    renderPopover({ onResize, onClose });

    await userEvent.click(page.getByTitle('Change size'));
    await userEvent.click(page.getByRole('button', { name: 'XS', exact: true }));

    expect(onResize).toHaveBeenCalledWith('xs');
    expect(onClose).toHaveBeenCalledOnce();
  });

  it('hides size menu after selecting a size', async () => {
    renderPopover();

    await userEvent.click(page.getByTitle('Change size'));
    await expect.element(page.getByTestId('size-menu')).toBeVisible();

    await userEvent.click(page.getByRole('button', { name: 'XS', exact: true }));
    await expect.element(page.getByTestId('size-menu')).not.toBeInTheDocument();
  });

  describe('when currentSize is undefined (block mode)', () => {
    it('shows "Inline" button instead of "Change size"', async () => {
      renderPopover({ currentSize: undefined });

      await expect.element(page.getByTitle('Convert to inline')).toBeVisible();
    });

    it('shows inline size options without M', async () => {
      renderPopover({ currentSize: undefined });

      await userEvent.click(page.getByTitle('Convert to inline'));

      await expect.element(page.getByRole('button', { name: 'XXS', exact: true })).toBeVisible();
      await expect.element(page.getByRole('button', { name: 'XS', exact: true })).toBeVisible();
      await expect.element(page.getByRole('button', { name: 'S', exact: true })).toBeVisible();
      await expect.element(page.getByRole('button', { name: 'M', exact: true })).not.toBeInTheDocument();
    });

    it('calls onConvertToInline when an inline size is selected', async () => {
      const onConvertToInline = vi.fn();
      const onClose = vi.fn();
      renderPopover({ currentSize: undefined, onConvertToInline, onClose });

      await userEvent.click(page.getByTitle('Convert to inline'));
      await userEvent.click(page.getByRole('button', { name: 'S', exact: true }));

      expect(onConvertToInline).toHaveBeenCalledWith('s');
      expect(onClose).toHaveBeenCalledOnce();
    });
  });
});