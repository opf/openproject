import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, cleanup } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { useState } from 'react';
import { InlineWorkPackageChip } from '../../../../lib/components/InlineWorkPackage/InlineWorkPackageChip';
import { worker } from '../../../mocks/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { insertBlockWorkPackageViaSlashMenu } from '../../../helpers/editorHelpers';

afterEach(() => {
  cleanup();
  worker.resetHandlers();
});

// Insert an inline work package whose detail fetch fails (the search list is
// mocked separately, so the search flow still succeeds).
async function insertUnavailableInlineWorkPackage() {
  const editorEl = page.getByRole('textbox');
  await expect.element(editorEl).toBeVisible();
  await userEvent.click(editorEl);
  await userEvent.type(editorEl, ' /');

  await expect.element(page.getByText('Link existing work package').first()).toBeVisible();
  await userEvent.click(page.getByText('Link existing work package').first());

  const searchInput = page.getByPlaceholder('Search by work package ID or subject');
  await expect.element(searchInput).toBeVisible();
  await userEvent.type(searchInput, 'Fix');
  await expect.element(page.getByText('Fix login bug')).toBeVisible();
  await userEvent.click(page.getByText('Fix login bug'));

  await expect.element(searchInput).not.toBeInTheDocument();
}

describe('Inline chip - unavailable work package', () => {
  it('shows eye-closed icon and "Unavailable: No permission" on 404', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/999', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    render(
      <InlineWorkPackageChip
        inlineContent={{ props: { wpid: '999', size: 's', displayId: '999' } }}
        contentRef={vi.fn()}
      />
    );

    await expect.element(page.getByText('Unavailable: No permission')).toBeVisible();
    const chip = page.getByText('Unavailable: No permission').element().closest('.op-bn-inline-wp');
    expect(chip?.querySelector('.octicon-eye-closed')).not.toBeNull();

    expect(chip?.querySelector('.op-bn-work-package--id')?.textContent).toBe('#999');
    const link = chip?.querySelector('a');
    expect(link?.textContent).toBe('Unavailable');
    expect(link?.getAttribute('href')).toBe('http://localhost:3000/wp/999');
  });

  it('shows alert icon and "Unavailable: error" on server error', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/999', () =>
        HttpResponse.json({ message: 'Internal Server Error' }, { status: 500 })
      )
    );

    render(
      <InlineWorkPackageChip
        inlineContent={{ props: { wpid: '999', size: 's', displayId: '999' } }}
        contentRef={vi.fn()}
      />
    );

    await expect.element(page.getByText('Unavailable: error')).toBeVisible();
    expect(
      page.getByText('Unavailable: error').element().closest('.op-bn-inline-wp')?.querySelector('.octicon-alert')
    ).not.toBeNull();
  });

  it('renders only the icon with an aria-label and no native tooltip for size xxs', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/999', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    render(
      <InlineWorkPackageChip
        inlineContent={{ props: { wpid: '999', size: 'xxs', displayId: '999' } }}
        contentRef={vi.fn()}
      />
    );

    await vi.waitFor(() => {
      expect(document.querySelector('.op-bn-inline-wp .octicon-eye-closed')).not.toBeNull();
    });
    const chip = document.querySelector('.op-bn-inline-wp');
    expect(chip?.textContent).toBe('');
    // The full message now lives in the hover/long-press preview, not a native tooltip.
    expect(chip?.getAttribute('title')).toBeNull();
    expect(chip?.getAttribute('aria-label')).toBe('Unavailable: No permission');
  });

  it('shows the unavailable card in the preview on hover for size xxs', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/999', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    render(
      <InlineWorkPackageChip
        inlineContent={{ props: { wpid: '999', size: 'xxs', instanceId: 'test-xxs-preview' } }}
        contentRef={vi.fn()}
      />
    );

    await vi.waitFor(() => {
      expect(document.querySelector('.op-bn-inline-wp .octicon-eye-closed')).not.toBeNull();
    });

    await userEvent.hover(page.getByRole('img'));

    await expect.element(page.getByTestId('wp-preview')).toBeVisible();
    await expect.element(page.getByText('Linked work package unavailable')).toBeVisible();
    await expect.element(page.getByText('You do not have permission to see this')).toBeVisible();
    // The known-format card icon is reused from the block card.
    const header = document.querySelector('.op-bn-unavailable-message--header');
    expect(header?.querySelector('.octicon-eye-closed')).not.toBeNull();

    expect(header?.querySelector('.op-bn-work-package--id')?.textContent).toBe('#999');
    const link = header?.querySelector('a');
    expect(link?.textContent).toBe('work package');
    expect(link?.getAttribute('href')).toBe('http://localhost:3000/wp/999');
  });

  it('gets the selection outline on click and can be copied and pasted', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/123', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    renderEditor();
    await insertUnavailableInlineWorkPackage();

    await expect.element(page.getByText('Unavailable: No permission')).toBeVisible();
    // click the identifier, not the label — its "Unavailable" word is a link
    await userEvent.click(page.getByText('#123'));

    await expect.poll(() => {
      const base = document.querySelector('.op-bn-inline-wp .op-bn-inline-wp-base');
      return base ? getComputedStyle(base).boxShadow : '';
    }).toContain('inset');

    await userEvent.keyboard('{Control>}c{/Control}');
    await userEvent.keyboard('{Control>}{End}{/Control}');
    await userEvent.keyboard('{Enter}');
    await userEvent.keyboard('{Control>}v{/Control}');

    await vi.waitFor(() => {
      expect(document.querySelectorAll('.op-bn-inline-wp').length).toBe(2);
    });
  });
});

// Unauthorized chip whose size is held in state, so resizing re-renders
function UnavailableChipWrapper({ initialSize }:{ initialSize:string }) {
  const [size, setSize] = useState(initialSize);

  return (
    <div style={{ paddingTop: '200px', paddingLeft: '20px' }}>
      <InlineWorkPackageChip
        inlineContent={{ props: { wpid: '999', size, displayId: '999' } }}
        contentRef={vi.fn()}
        updateInlineContent={(update) => setSize(update.props.size)}
      />
    </div>
  );
}

describe('Unavailable work package - options popover (BNE-112)', () => {
  it('inline chip: opens the popover without the Open button and resizes', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/999', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    render(<UnavailableChipWrapper initialSize="s" />);

    await expect.element(page.getByText('Unavailable: No permission')).toBeVisible();
    // click the identifier, not the label — its "Unavailable" word is a link
    await userEvent.click(page.getByText('#999'));

    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await expect.element(page.getByTitle('Open in new tab')).not.toBeInTheDocument();

    await userEvent.click(page.getByTitle('Change size'));
    await expect.element(page.getByTestId('size-menu')).toBeVisible();
    await userEvent.click(page.getByRole('button', { name: 'Tiny', exact: true }));

    // xxs renders icon-only with the message exposed to assistive tech via aria-label
    await vi.waitFor(() => {
      expect(document.querySelector('.op-bn-inline-wp')?.getAttribute('aria-label')).toBe('Unavailable: No permission');
    });
  });

  it('inline chip: removes the chip from the document', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/123', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    renderEditor();
    await insertUnavailableInlineWorkPackage();

    await expect.element(page.getByText('Unavailable: No permission')).toBeVisible();
    // click the identifier, not the label — its "Unavailable" word is a link
    await userEvent.click(page.getByText('#123'));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();

    await userEvent.click(page.getByTitle('Remove'));

    await expect.element(page.getByText('Unavailable: No permission')).not.toBeInTheDocument();
  });

  it('block card: opens the popover without the Open button and removes the block', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/123', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    renderEditor();
    await insertBlockWorkPackageViaSlashMenu();

    await expect.element(page.getByText('Linked work package unavailable')).toBeVisible();
    // click the message, not the header — its "work package" words are a link
    await userEvent.click(page.getByText('You do not have permission to see this'));

    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await expect.element(page.getByTitle('Open in new tab')).not.toBeInTheDocument();

    await userEvent.click(page.getByTitle('Remove'));

    await expect.element(page.getByTestId('block-wp-wrapper')).not.toBeInTheDocument();
  });
});

describe('Block card - unavailable work package', () => {
  it('shows eye-closed icon and "Linked work package unavailable" on 404', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/123', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    renderEditor();
    await insertBlockWorkPackageViaSlashMenu();

    await expect.element(page.getByText('Linked work package unavailable')).toBeVisible();
    await expect.element(page.getByText('You do not have permission to see this')).toBeVisible();
    const header = document.querySelector('.op-bn-unavailable-message--header');
    expect(header?.querySelector('.octicon-eye-closed')).not.toBeNull();

    expect(header?.querySelector('.op-bn-work-package--id')?.textContent).toBe('#123');
    const link = header?.querySelector('a');
    expect(link?.textContent).toBe('work package');
    expect(link?.getAttribute('href')).toBe('http://localhost:3000/wp/123');
  });

  it('shows alert icon and "Error" on server error', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/123', () =>
        HttpResponse.json({ message: 'Internal Server Error' }, { status: 500 })
      )
    );

    renderEditor();
    await insertBlockWorkPackageViaSlashMenu();

    await expect.element(page.getByText('Error', { exact: true })).toBeVisible();
    await expect.element(page.getByText('Could not load work package')).toBeVisible();
    expect(document.querySelector('.op-bn-unavailable-message--header .octicon-alert')).not.toBeNull();
  });
});
