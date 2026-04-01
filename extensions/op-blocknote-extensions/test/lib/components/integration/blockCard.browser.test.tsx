import { describe, it, expect, vi } from 'vitest';
import { render } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { BlockCard } from '../../../../lib/components/BlockWorkPackage/BlockCard';
import { mockWorkPackage } from '../../../mocks/handlers';
import type { WorkPackage } from '../../../../lib/openProjectTypes';

const wp = mockWorkPackage as unknown as WorkPackage;

describe('BlockCard', () => {
  it('renders work package subject, type, id and status', async () => {
  render(<BlockCard workPackage={wp} />);

  await expect.element(page.getByText('Fix login bug', { exact: true })).toBeVisible();
  await expect.element(page.getByTestId('op-bn-work-package--type')).toHaveTextContent('Bug');
  await expect.element(page.getByText('#123', { exact: true })).toBeVisible();
  await expect.element(page.getByText('In Progress', { exact: true })).toBeVisible();
});

  it('renders subject as plain text when linkTitle is false', async () => {
    render(<BlockCard workPackage={wp} />);

    const subject = page.getByText('Fix login bug');
    await expect.element(subject).toBeVisible();

    const tag = await subject.element();
    expect(tag.tagName.toLowerCase()).not.toBe('a');
  });

  it('renders subject as a link when linkTitle is true', async () => {
    render(<BlockCard workPackage={wp} linkTitle />);

    const link = page.getByRole('link', { name: 'Fix login bug' });
    await expect.element(link).toBeVisible();
    await expect.element(link).toHaveAttribute('href', expect.stringContaining(`/wp/${wp.id}`));
  });

  it('opens WP in new tab without navigating current page when linkTitle link is clicked', async () => {
    const openSpy = vi.spyOn(window, 'open').mockReturnValue(null);
    render(<BlockCard workPackage={wp} linkTitle />);

    await userEvent.click(page.getByRole('link', { name: 'Fix login bug' }));

    expect(openSpy).toHaveBeenCalledOnce();
    expect(openSpy).toHaveBeenCalledWith(
      expect.stringContaining(`/wp/${wp.id}`),
      '_blank',
      'noopener,noreferrer'
    );

    await expect.element(page.getByText('Fix login bug')).toBeInTheDocument();
    openSpy.mockRestore();
  });

  it('calls onClick when the card is clicked', async () => {
    const onClick = vi.fn();
    render(<BlockCard workPackage={wp} onClick={onClick} />);

    await userEvent.click(page.getByText('Fix login bug'));

    expect(onClick).toHaveBeenCalledOnce();
  });

  it('renders with inDropdown styling (smoke test — no crash)', async () => {
    render(<BlockCard workPackage={wp} inDropdown />);

    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('applies data-testid on the type element', async () => {
    render(<BlockCard workPackage={wp} />);

    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toHaveTextContent('Bug');
  });
});