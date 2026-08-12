import { describe, it, expect, vi, afterEach } from 'vitest';
import { render } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse, delay } from 'msw';
import { SearchDropdown } from '../../../../lib/components/Search/SearchDropdown';
import { BlockCard } from '../../../../lib/components/BlockWorkPackage/BlockCard';
import { mockWorkPackage, mockWorkPackage2 } from '../../../mocks/handlers';
import { worker } from '../../../mocks/browser';
import type { WorkPackage } from '../../../../lib/openProjectTypes';

const renderItem = (wp:WorkPackage) => <BlockCard workPackage={wp} inDropdown />;

const WORK_PACKAGES_ENDPOINT = 'http://localhost:3000/api/v3/work_packages';

afterEach(() => {
  worker.resetHandlers();
});

describe('SearchDropdown', () => {
  it('shows results after typing', async () => {
    render(
      <SearchDropdown onSelect={vi.fn()} onCancel={vi.fn()} renderItem={renderItem} />
    );

    const input = page.getByRole('searchbox');
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

    await userEvent.type(page.getByRole('searchbox'), 'bug');
    await expect.element(page.getByText('Fix login bug')).toBeVisible();

    await userEvent.click(page.getByText('Fix login bug'));

    expect(onSelect).toHaveBeenCalledExactlyOnceWith(expect.objectContaining({ id: mockWorkPackage.id }));
  });

  it('calls onCancel when pressing Escape', async () => {
    const onCancel = vi.fn();
    render(
      <SearchDropdown onSelect={vi.fn()} onCancel={onCancel} renderItem={renderItem} />
    );

    const input = page.getByRole('searchbox');
    await userEvent.click(input);
    await userEvent.keyboard('{Escape}');

    expect(onCancel).toHaveBeenCalledOnce();
  });

  it('selects first result with Enter without pressing arrow keys', async () => {
    const onSelect = vi.fn();
    render(
      <SearchDropdown onSelect={onSelect} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await userEvent.type(page.getByRole('searchbox'), 'Fix');
    await expect.element(page.getByText('Fix login bug')).toBeVisible();

    await userEvent.keyboard('{Enter}');

    expect(onSelect).toHaveBeenCalledExactlyOnceWith(
      expect.objectContaining({ id: mockWorkPackage.id })
    );
  });

  it('navigates results with arrow keys and selects with Enter', async () => {
    const onSelect = vi.fn();
    render(
        <SearchDropdown onSelect={onSelect} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await userEvent.type(page.getByRole('searchbox'), 'mode');
    await expect.element(page.getByText('Add dark mode')).toBeVisible();

    // First item is auto-selected; ArrowDown moves to the second item.
    await userEvent.keyboard('{ArrowDown}{Enter}');

    expect(onSelect).toHaveBeenCalledExactlyOnceWith(
        expect.objectContaining({ id: mockWorkPackage2.id })
    );
    });

  it('shows a spinner while the search is running', async () => {
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, async () => {
        await delay(300);
        return HttpResponse.json({ _embedded: { elements: [mockWorkPackage] } });
      })
    );

    render(
      <SearchDropdown onSelect={vi.fn()} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await userEvent.type(page.getByRole('searchbox'), 'Fix');

    const spinner = page.getByRole('img', { name: 'Loading' });
    await expect.element(spinner).toBeVisible();

    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(spinner).not.toBeInTheDocument();
  });

  it('shows "No results" when the search returns nothing', async () => {
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, () =>
        HttpResponse.json({ _embedded: { elements: [] } })
      )
    );

    render(
      <SearchDropdown onSelect={vi.fn()} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await userEvent.type(page.getByRole('searchbox'), 'nothing');

    await expect.element(page.getByText('No results')).toBeVisible();
  });

  it('shows an error message when the search request fails', async () => {
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, () => HttpResponse.error())
    );

    render(
      <SearchDropdown onSelect={vi.fn()} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await userEvent.type(page.getByRole('searchbox'), 'Fix');

    await expect.element(page.getByText('Error. Unable to load content.')).toBeVisible();
  });

  it('limits results to 5 items maximum', async () => {
    render(
      <SearchDropdown onSelect={vi.fn()} onCancel={vi.fn()} renderItem={renderItem} />
    );

    await userEvent.type(page.getByRole('searchbox'), 'any');
    await expect.element(page.getByText('Fix login bug')).toBeVisible();

    const items = page.getByTestId('dropdown-item');
    expect((await items.all()).length).toBeLessThanOrEqual(5);
  });
});