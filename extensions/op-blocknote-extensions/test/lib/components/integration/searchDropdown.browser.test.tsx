import { describe, it, expect, vi } from 'vitest';
import { render } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { SearchDropdown } from '../../../../lib/components/Search/SearchDropdown'
import { BlockCard } from '../../../../lib/components/BlockWorkPackage/BlockCard';
import { mockWorkPackage } from '../../../mocks/handlers';
import type { WorkPackage } from '../../../../lib/openProjectTypes';

const renderItem = (wp: WorkPackage) => <BlockCard workPackage={wp} inDropdown />;

describe('SearchDropdown', () => {
  it('renders the search input', async () => {
    render(
      <SearchDropdown onSelect={vi.fn()} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await expect.element(page.getByRole('textbox')).toBeInTheDocument();
  });

  it('does not show dropdown before typing', async () => {
    render(
      <SearchDropdown onSelect={vi.fn()} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await expect.element(page.getByText('Fix login bug')).not.toBeInTheDocument();
  });

  it('shows results after typing', async () => {
    render(
      <SearchDropdown onSelect={vi.fn()} onCancel={vi.fn()} renderItem={renderItem} />
    );

    const input = page.getByRole('textbox');
    await userEvent.type(input, 'Fix');

    // Wait for debounce + MSW response
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByText('Add dark mode')).toBeVisible();
  });

  it('calls onSelect when clicking a result', async () => {
    const onSelect = vi.fn();
    render(
      <SearchDropdown onSelect={onSelect} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await userEvent.type(page.getByRole('textbox'), 'bug');
    await expect.element(page.getByText('Fix login bug')).toBeVisible();

    await userEvent.click(page.getByText('Fix login bug'));

    expect(onSelect).toHaveBeenCalledOnce();
    expect(onSelect).toHaveBeenCalledWith(expect.objectContaining({ id: mockWorkPackage.id }));
  });

  it('calls onCancel when pressing Escape', async () => {
    const onCancel = vi.fn();
    render(
      <SearchDropdown onSelect={vi.fn()} onCancel={onCancel} renderItem={renderItem} />
    );

    const input = page.getByRole('textbox');
    await userEvent.click(input);
    await userEvent.keyboard('{Escape}');

    expect(onCancel).toHaveBeenCalledOnce();
  });

  it('navigates results with arrow keys and selects with Enter', async () => {
    const onSelect = vi.fn();
    render(
        <SearchDropdown onSelect={onSelect} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await userEvent.type(page.getByRole('textbox'), 'mode');
    await expect.element(page.getByText('Add dark mode')).toBeVisible();

    await userEvent.keyboard('{ArrowDown}{Enter}');

    expect(onSelect).toHaveBeenCalledOnce();
    expect(onSelect).toHaveBeenCalledWith(
        expect.objectContaining({ id: mockWorkPackage.id })
    );
    });

  it('limits results to 5 items maximum', async () => {
    render(
      <SearchDropdown onSelect={vi.fn()} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await userEvent.type(page.getByRole('textbox'), 'any');
    await expect.element(page.getByText('Fix login bug')).toBeVisible();

    const items = page.getByTestId('dropdown-item');
    expect((await items.all()).length).toBeLessThanOrEqual(5);
  });

  it('focuses input automatically when autoFocus is set', async () => {
    render(
      <SearchDropdown autoFocus onSelect={vi.fn()} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await expect.element(page.getByRole('textbox')).toHaveFocus();
  });
});