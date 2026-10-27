import { describe, it, expect, afterEach } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { openEditorAndType } from '../../../helpers/editorHelpers';

const TRANSPARENT = 'rgba(0, 0, 0, 0)';

async function openHashMenu() {
  renderEditor();
  await openEditorAndType('#Fix');
  await expect.element(page.getByText('Add dark mode')).toBeVisible();
  return Array.from(document.querySelectorAll('.op-bn-hash-menu-item'));
}

function highlightedRows(rows:Element[]) {
  return rows
    .map((row, index) => ({ index, background: getComputedStyle(row).backgroundColor }))
    .filter(({ background }) => background !== TRANSPARENT)
    .map(({ index }) => index);
}

describe('Hash menu - row highlighting', () => {
  it('highlights the first row while nothing else has been pointed at', async () => {
    const rows = await openHashMenu();

    expect(highlightedRows(rows)).toEqual([0]);
  });

  it('hands the single highlight to the row under the pointer', async () => {
    const rows = await openHashMenu();

    await userEvent.hover(page.getByText('Semantic ID work package'));

    expect(highlightedRows(rows)).toEqual([2]);
  });

  it('gives the highlight back to the keyboard selection', async () => {
    const rows = await openHashMenu();
    await userEvent.hover(page.getByText('Semantic ID work package'));
    expect(highlightedRows(rows)).toEqual([2]);

    await userEvent.keyboard('{ArrowDown}');

    expect(highlightedRows(rows)).toEqual([1]);
  });

  it('inserts the work package the pointer is on from the click alone', async () => {
    const rows = await openHashMenu();

    rows[1].dispatchEvent(new MouseEvent('click', { bubbles: true }));

    await expect.element(page.getByText('#456')).toBeVisible();
  });
});

describe('Hash menu - row highlighting without a hovering pointer', () => {
  const realMatchMedia = window.matchMedia.bind(window);

  afterEach(() => {
    window.matchMedia = realMatchMedia;
  });

  function reportTouchScreen() {
    window.matchMedia = (query:string) => (
      query.includes('hover')
        ? { ...realMatchMedia(query), matches: query.includes('hover: none') }
        : realMatchMedia(query)
    );
  }

  it('keeps the highlight on the selected row when the pointer cannot hover', async () => {
    reportTouchScreen();
    const rows = await openHashMenu();

    await userEvent.hover(page.getByText('Semantic ID work package'));

    expect(highlightedRows(rows)).toEqual([0]);
  });
});
