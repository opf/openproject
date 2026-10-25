import { describe, it, expect, afterEach } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { renderEditor } from '../../../helpers/renderEditor';
import { insertInlineWorkPackageViaSlashMenu, convertToCompactCard } from '../../../helpers/editorHelpers';
import { worker } from '../../../mocks/browser';
import { mockWorkPackage } from '../../../mocks/handlers';

describe('Drag and drop - inline chip', () => {
  afterEach(() => worker.resetHandlers());

  it('chip has data-drag-handle and is not independently draggable', async () => {
    renderEditor();

    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'Before ');
    await insertInlineWorkPackageViaSlashMenu();

    await expect.element(page.getByText('#123')).toBeVisible();

    const chipEl = page.getByText('#123').element().closest('.op-bn-inline-wp')!;
    expect(chipEl).not.toBeNull();
    expect(chipEl.hasAttribute('data-drag-handle')).toBe(true);
    expect(chipEl.getAttribute('draggable')).not.toBe('true');
  });

  it('dragging chip block does not create a duplicate', async () => {
    renderEditor();

    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'First line');
    await userEvent.keyboard('{Enter}');
    await insertInlineWorkPackageViaSlashMenu();
    await userEvent.keyboard('{Enter}');
    await userEvent.type(editor, 'Last line');

    await expect.element(page.getByText('#123')).toBeVisible();
    expect(document.querySelectorAll('.op-bn-inline-wp')).toHaveLength(1);

    await userEvent.dragAndDrop(
      document.querySelector('.op-bn-inline-wp')!,
      page.getByText('Last line'),
    );

    await expect.element(page.getByText('#123')).toBeVisible();
    expect(document.querySelectorAll('.op-bn-inline-wp')).toHaveLength(1);

    // Verify chip actually moved into the "Last line" block (inline drop splits the text node,
    // so getByText('Last line') won't find it whole - check via the block container instead)
    const chipEl = document.querySelector('.op-bn-inline-wp')!;
    const chipBlock = chipEl.closest('[data-node-type="blockOuter"]');
    expect(chipBlock?.textContent).toContain('Last');
  });

  it('drag and drop does not re-fetch the work package from the server', async () => {
    renderEditor();

    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await insertInlineWorkPackageViaSlashMenu();
    await userEvent.keyboard('{Enter}');
    await userEvent.type(editor, 'Last line');

    await expect.element(page.getByText('#123')).toBeVisible();

    let fetchCount = 0;
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/:id', ({ params }) => {
        fetchCount += 1;
        return HttpResponse.json({ ...mockWorkPackage, id: Number(params.id), displayId: String(params.id) });
      })
    );

    await userEvent.dragAndDrop(
      document.querySelector('.op-bn-inline-wp')!,
      page.getByText('Last line'),
    );

    await expect.element(page.getByText('#123')).toBeVisible();
    expect(fetchCount).toBe(0);
  });
});

describe('Drag and drop - block card', () => {
  afterEach(() => worker.resetHandlers());

  it('block card container is draggable', async () => {
    renderEditor();

    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();

    const blockContainer = page.getByTestId('block-card').element().closest('.op-bn-extensions')!;
    expect(blockContainer).not.toBeNull();
    expect(blockContainer.getAttribute('draggable')).toBe('true');
  });

  it('drag and drop does not re-fetch the work package from the server', async () => {
    renderEditor();

    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();
    // Add a paragraph below the card to serve as the drop target
    await userEvent.keyboard('{Enter}');
    await userEvent.type(editor, 'After card');

    await expect.element(page.getByTestId('block-card')).toBeVisible();

    let fetchCount = 0;
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/:id', ({ params }) => {
        fetchCount += 1;
        return HttpResponse.json({ ...mockWorkPackage, id: Number(params.id), displayId: String(params.id) });
      })
    );

    // Drop onto the block-level container of the target paragraph, not the text span,
    // so ProseMirror can resolve a valid block-level drop position.
    const blockContainer = page.getByTestId('block-card').element().closest('.op-bn-extensions')!;
    const dropTarget = page.getByText('After card').element().closest('[data-node-type="blockOuter"]')!;
    await userEvent.dragAndDrop(blockContainer, dropTarget);

    // Yield to the browser event loop so React effects have time to run
    await new Promise<void>(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));

    expect(fetchCount).toBe(0);
  });
});
