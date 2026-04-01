import { describe, it, expect, vi } from 'vitest';
import { render } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { worker } from '../../../mocks/browser';
import { InlineWorkPackageChip } from '../../../../lib/components/InlineWorkPackage/InlineWorkPackageChip';
import { mockWorkPackage } from '../../../mocks/handlers';

function makeInlineContent(wpid: string, size = 's', instanceId = 'test-iid') {
  return { props: { wpid, size, instanceId } };
}

describe('InlineWorkPackageChip', () => {
  describe('loading state', () => {
    it('shows #id… placeholder while fetching', async () => {
      worker.use(
        http.get('http://localhost:3000/api/v3/work_packages/:id', async () => {
          await new Promise((r) => setTimeout(r, 300));
          return HttpResponse.json(mockWorkPackage);
        })
      );

      render(
        <InlineWorkPackageChip
          inlineContent={makeInlineContent('123')}
          contentRef={vi.fn()}
        />
      );

      await expect.element(page.getByText('#123…')).toBeVisible();
    });
  });

  describe('resolved state', () => {
    it('renders XXS chip — only the ID', async () => {
      render(
        <InlineWorkPackageChip
          inlineContent={makeInlineContent('123', 'xxs')}
          contentRef={vi.fn()}
        />
      );

      await expect.element(page.getByText('#123')).toBeVisible();
      await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
      await expect.element(page.getByText('Fix login bug')).not.toBeInTheDocument();
    });

    it('renders XS chip — ID, type, subject (no status)', async () => {
      render(
        <InlineWorkPackageChip
          inlineContent={makeInlineContent('123', 'xs')}
          contentRef={vi.fn()}
        />
      );

      await expect.element(page.getByText('#123')).toBeVisible();
      await expect.element(page.getByTestId('op-bn-work-package--type')).toHaveTextContent('Bug');
      await expect.element(page.getByText('Fix login bug')).toBeVisible();
      await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
    });

    it('renders S chip — ID, type, status, subject', async () => {
      render(
        <InlineWorkPackageChip
          inlineContent={makeInlineContent('123', 's')}
          contentRef={vi.fn()}
        />
      );

      await expect.element(page.getByText('#123')).toBeVisible();
      await expect.element(page.getByTestId('op-bn-work-package--type')).toHaveTextContent('Bug');
      await expect.element(page.getByText('In Progress')).toBeVisible();
      await expect.element(page.getByText('Fix login bug')).toBeVisible();
    });

    it('opens options popover on click', async () => {
      render(
        <InlineWorkPackageChip
          inlineContent={makeInlineContent('123', 's')}
          contentRef={vi.fn()}
        />
      );

      await expect.element(page.getByText('#123')).toBeVisible();
      await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();

      await userEvent.click(page.getByText('In Progress'));

      await expect.element(page.getByTestId('popover-content')).toBeVisible();
    });

    it('closes options popover on outside click', async () => {
      render(
        <div>
          <InlineWorkPackageChip
            inlineContent={makeInlineContent('123', 's')}
            contentRef={vi.fn()}
          />
          <div data-testid="outside">Outside</div>
        </div>
      );

      await expect.element(page.getByText('#123')).toBeVisible();
      await userEvent.click(page.getByText('In Progress'));
      await expect.element(page.getByTestId('popover-content')).toBeVisible();

      await userEvent.click(page.getByTestId('outside'));
      await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
    });

    it('toggles popover off on second click', async () => {
      render(
        <InlineWorkPackageChip
          inlineContent={makeInlineContent('123', 's')}
          contentRef={vi.fn()}
        />
      );

      await expect.element(page.getByText('#123')).toBeVisible();

      await userEvent.click(page.getByText('In Progress'));
      await expect.element(page.getByTestId('popover-content')).toBeVisible();

      await userEvent.click(page.getByText('In Progress'));
      await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
    });
  });

  describe('error state', () => {
    it('renders fallback #id chip when WP fetch fails', async () => {
      worker.use(
        http.get('http://localhost:3000/api/v3/work_packages/999', () =>
          HttpResponse.json({ message: 'Not Found' }, { status: 404 })
        )
      );

      render(
        <InlineWorkPackageChip
          inlineContent={makeInlineContent('999', 's')}
          contentRef={vi.fn()}
        />
      );

      await expect.element(page.getByText('#999')).toBeVisible();
      await expect.element(page.getByText('Fix login bug')).not.toBeInTheDocument();
    });
  });

  describe('pending state', () => {
    it('renders an empty chip for a pending wpid with no callbacks registered', async () => {
      render(
        <InlineWorkPackageChip
          inlineContent={makeInlineContent('pending:orphan-iid', 's', 'orphan-iid')}
          contentRef={vi.fn()}
        />
      );

      await expect.element(page.getByText('Fix login bug')).not.toBeInTheDocument();
    });
  });
});