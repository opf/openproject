import { describe, it, expect, vi } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';

// Regression coverage for chip actions when two *identical* chips (same wpid)
// sit in the *same* paragraph. Actions are targeted by the chip's own
// ProseMirror position, so — unlike the copy/paste tests, which put each
// chip in its own paragraph — this exercises the ordinal mapping used to
// find the right chip among several siblings.
async function renderTwoIdenticalChipsInOneParagraph():Promise<void> {
  let editor:{ document:unknown; replaceBlocks:(oldBlocks:unknown, newBlocks:unknown) => void };
  renderEditor({ onEditor: (e) => { editor = e; } });

  await expect.element(page.getByRole('textbox')).toBeVisible();

  editor.replaceBlocks(editor.document, [
    {
      type: 'paragraph',
      content: [
        { type: 'openProjectWorkPackageInline', props: { wpid: '123', size: 's' } },
        { type: 'text', text: ' and ', styles: {} },
        { type: 'openProjectWorkPackageInline', props: { wpid: '123', size: 's' } },
      ],
    },
  ]);

  await expect.element(page.getByText('#123').first()).toBeVisible();
  expect((await page.getByText('#123').all()).length).toBe(2);
}

describe('Inline chip - identical chips in the same paragraph', () => {
  it('resizing the second chip does not affect the first', async () => {
    await renderTwoIdenticalChipsInOneParagraph();

    await userEvent.click(page.getByText('#123').nth(1));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await userEvent.click(page.getByTitle('Change size'));
    await expect.element(page.getByTestId('size-menu')).toBeVisible();
    await userEvent.click(page.getByRole('button', { name: 'Tiny', exact: true }));

    // Only the second chip shrank to XXS (no status badge); the first chip
    // stays at S and keeps its status badge.
    const statusBadges = page.getByText('In Progress');
    expect((await statusBadges.all()).length).toBe(1);
    expect((await page.getByText('#123').all()).length).toBe(2);
  });

  it('resizing the first chip does not affect the second', async () => {
    await renderTwoIdenticalChipsInOneParagraph();

    await userEvent.click(page.getByText('#123').nth(0));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await userEvent.click(page.getByTitle('Change size'));
    await expect.element(page.getByTestId('size-menu')).toBeVisible();
    await userEvent.click(page.getByRole('button', { name: 'Tiny', exact: true }));

    const statusBadges = page.getByText('In Progress');
    expect((await statusBadges.all()).length).toBe(1);
    expect((await page.getByText('#123').all()).length).toBe(2);
  });

  it('removing the second chip leaves the first and the surrounding text intact', async () => {
    await renderTwoIdenticalChipsInOneParagraph();

    await userEvent.click(page.getByText('#123').nth(1));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await userEvent.click(page.getByTestId('remove-btn'));

    expect((await page.getByText('#123').all()).length).toBe(1);
    await expect.element(page.getByText('and', { exact: false })).toBeVisible();
  });

  it('removing the first chip leaves the second and the surrounding text intact', async () => {
    await renderTwoIdenticalChipsInOneParagraph();

    await userEvent.click(page.getByText('#123').nth(0));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await userEvent.click(page.getByTestId('remove-btn'));

    expect((await page.getByText('#123').all()).length).toBe(1);
    await expect.element(page.getByText('and', { exact: false })).toBeVisible();
  });

  it('promoting the second chip to a block card leaves the first chip inline', async () => {
    await renderTwoIdenticalChipsInOneParagraph();

    await userEvent.click(page.getByText('#123').nth(1));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await userEvent.click(page.getByTitle('Change size'));
    await expect.element(page.getByTestId('size-menu')).toBeVisible();
    await userEvent.click(page.getByRole('button', { name: 'Compact card', exact: true }));

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    // The first chip remains an inline chip; only the second became a block card.
    await vi.waitFor(() => {
      expect(document.querySelectorAll('.op-bn-inline-wp').length).toBe(1);
    });
  });
});
