import { describe, it, expect, vi, afterEach } from 'vitest';
import type { ComponentProps, ReactNode } from 'react';
import { render } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse, delay } from 'msw';
import { SearchDropdown } from '../../../../lib/components/Search/SearchDropdown';
import { BlockCard } from '../../../../lib/components/BlockWorkPackage/BlockCard';
import { mockWorkPackage, mockWorkPackage2 } from '../../../mocks/handlers';
import { worker } from '../../../mocks/browser';
import type { WorkPackage } from '../../../../lib/openProjectTypes';

const renderItem = (wp:WorkPackage) => <BlockCard workPackage={wp} inDropdown />;

const searchDropdown = (props:Partial<ComponentProps<typeof SearchDropdown>> = {}) => (
  <SearchDropdown
    onSelect={vi.fn()}
    onCancel={vi.fn()}
    renderItem={renderItem}
    {...props}
  />
);

const WORK_PACKAGES_ENDPOINT = 'http://localhost:3000/api/v3/work_packages';

const SHORT_VIEWPORT_HEIGHT = 140;

const ShortViewport = ({ children }:{ children:ReactNode }) => (
  <div style={{ display: 'flex', flexDirection: 'column', height: SHORT_VIEWPORT_HEIGHT }}>
    {children}
  </div>
);

const manyWorkPackages = Array.from({ length: 8 }, (_, index) => ({
  ...mockWorkPackage,
  id: 1000 + index,
  displayId: `${1000 + index}`,
  subject: `Scrollable result ${index + 1}`,
}));

// Fractional row heights leave a sub-pixel overhang even when fully scrolled.
const SUBPIXEL_TOLERANCE = 1;

const isFullyInView = (list:Element, option:Element) => {
  const listRect = list.getBoundingClientRect();
  const optionRect = option.getBoundingClientRect();
  return optionRect.top >= listRect.top - SUBPIXEL_TOLERANCE
    && optionRect.bottom <= listRect.bottom + SUBPIXEL_TOLERANCE;
};

afterEach(() => {
  worker.resetHandlers();
});

describe('SearchDropdown', () => {
  it('shows results after typing', async () => {
    render(searchDropdown());

    const input = page.getByRole('searchbox');
    await userEvent.type(input, 'Fix');

    // Wait for debounce + MSW response
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByText('Add dark mode')).toBeVisible();
  });

  it('calls onSelect when clicking a result', async () => {
    const onSelect = vi.fn();
    render(searchDropdown({ onSelect }));

    await userEvent.type(page.getByRole('searchbox'), 'bug');
    await expect.element(page.getByText('Fix login bug')).toBeVisible();

    await userEvent.click(page.getByText('Fix login bug'));

    expect(onSelect).toHaveBeenCalledExactlyOnceWith(expect.objectContaining({ id: mockWorkPackage.id }));
  });

  it('calls onCancel when pressing Escape', async () => {
    const onCancel = vi.fn();
    render(searchDropdown({ onCancel }));

    const input = page.getByRole('searchbox');
    await userEvent.click(input);
    await userEvent.keyboard('{Escape}');

    expect(onCancel).toHaveBeenCalledOnce();
  });

  it('selects first result with Enter without pressing arrow keys', async () => {
    const onSelect = vi.fn();
    render(searchDropdown({ onSelect }));

    await userEvent.type(page.getByRole('searchbox'), 'Fix');
    await expect.element(page.getByText('Fix login bug')).toBeVisible();

    await userEvent.keyboard('{Enter}');

    expect(onSelect).toHaveBeenCalledExactlyOnceWith(
      expect.objectContaining({ id: mockWorkPackage.id })
    );
  });

  it('navigates results with arrow keys and selects with Enter', async () => {
    const onSelect = vi.fn();
    render(searchDropdown({ onSelect }));

    await userEvent.type(page.getByRole('searchbox'), 'mode');
    await expect.element(page.getByText('Add dark mode')).toBeVisible();

    // First item is auto-selected; ArrowDown moves to the second item.
    await userEvent.keyboard('{ArrowDown}{Enter}');

    expect(onSelect).toHaveBeenCalledExactlyOnceWith(
        expect.objectContaining({ id: mockWorkPackage2.id })
    );
    });

  it('scrolls the focused result into view when arrow keys move past the visible ones', async () => {
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, () =>
        HttpResponse.json({ _embedded: { elements: manyWorkPackages } })
      )
    );

    render(
      <ShortViewport>{searchDropdown()}</ShortViewport>
    );

    await userEvent.type(page.getByRole('searchbox'), 'Scrollable');
    await expect.element(page.getByText('Scrollable result 1')).toBeVisible();

    const list = document.querySelector('[role="listbox"]')!;
    const options = list.querySelectorAll('[role="option"]');
    const lastOption = options[options.length - 1];
    expect(isFullyInView(list, lastOption)).toBe(false);

    await userEvent.keyboard('{ArrowDown}'.repeat(options.length - 1));

    expect(isFullyInView(list, lastOption)).toBe(true);

    await userEvent.keyboard('{ArrowUp}'.repeat(options.length - 1));

    expect(isFullyInView(list, options[0])).toBe(true);
  });

  it('shows a spinner while the search is running', async () => {
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, async () => {
        await delay(300);
        return HttpResponse.json({ _embedded: { elements: [mockWorkPackage] } });
      })
    );

    render(searchDropdown());

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

    render(searchDropdown());

    await userEvent.type(page.getByRole('searchbox'), 'nothing');

    await expect.element(page.getByText('No results')).toBeVisible();
  });

  it('shows an error message when the search request fails', async () => {
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, () => HttpResponse.error())
    );

    render(searchDropdown());

    await userEvent.type(page.getByRole('searchbox'), 'Fix');

    await expect.element(page.getByText('Error. Unable to load content.')).toBeVisible();
  });

  it('keeps the keyboard on the last shown result when the search returns more', async () => {
    const onSelect = vi.fn();
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, () =>
        HttpResponse.json({ _embedded: { elements: manyWorkPackages } })
      )
    );

    render(searchDropdown({ onSelect }));

    await userEvent.type(page.getByRole('searchbox'), 'Scrollable');
    await expect.element(page.getByText('Scrollable result 1')).toBeVisible();

    await userEvent.keyboard('{ArrowDown}'.repeat(manyWorkPackages.length));
    await userEvent.keyboard('{Enter}');

    expect(onSelect).toHaveBeenCalledExactlyOnceWith(
      expect.objectContaining({ subject: 'Scrollable result 5' })
    );
  });

  it('limits results to 5 items maximum', async () => {
    render(searchDropdown());

    await userEvent.type(page.getByRole('searchbox'), 'any');
    await expect.element(page.getByText('Fix login bug')).toBeVisible();

    const items = page.getByTestId('dropdown-item');
    expect((await items.all()).length).toBeLessThanOrEqual(5);
  });
});