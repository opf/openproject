import { afterEach, describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { openCreateModal } from '../../../helpers/createWorkPackageHelpers';
import { worker } from '../../../mocks/browser';

afterEach(() => worker.resetHandlers());

const PROJECT_FIELD = 'Project *';
const LIST = 'op-bn-create-wp-project-list';
const TOGGLE = 'op-bn-create-wp-project-toggle';
const CLEAR = 'op-bn-create-wp-project-clear';
const SEARCH = 'op-bn-create-wp-project-search';

async function openProjectPicker() {
  renderEditor();
  await openCreateModal();
  await userEvent.click(page.getByLabelText(PROJECT_FIELD));
  await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
}

function search(term:string) {
  return userEvent.fill(page.getByTestId(SEARCH), term);
}

function optionLabels() {
  return Array
    .from(document.querySelectorAll('[role="treeitem"]'))
    .map((option) => option.textContent ?? '');
}

function labelLeft(name:string):number {
  const option = page.getByRole('treeitem', { name }).element();
  const label = Array.from(option.children).find((child) => child.textContent === name);
  if (!label) throw new Error(`No label in the option "${name}"`);
  return label.getBoundingClientRect().left;
}

describe('Create work package - project picker', () => {
  it('folds the subprojects away until their parent is unfolded', async () => {
    await openProjectPicker();

    expect(optionLabels()).toEqual(['Demo project', 'Scrum project']);

    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toHaveAttribute('aria-expanded', 'false');
    await expect.element(page.getByRole('treeitem', { name: 'Scrum project' })).not.toHaveAttribute('aria-expanded');
  });

  it('unfolds a parent into its indented children, and folds it back', async () => {
    await openProjectPicker();

    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));

    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).toBeVisible();
    expect(optionLabels()).toEqual(['Demo project', 'Demo sub 1', 'Demo sub 2', 'Scrum project']);
    expect(labelLeft('Demo sub 1')).toBeGreaterThan(labelLeft('Demo project'));
    expect(labelLeft('Demo sub 2')).toBe(labelLeft('Demo sub 1'));

    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).not.toBeInTheDocument();
  });

  it('ties a subtree together with a line per level it sits in', async () => {
    await openProjectPicker();
    expect(document.querySelectorAll(`[data-testid="${LIST}-level-line"]`)).toHaveLength(0);

    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).toBeVisible();

    const lines = ['Demo sub 1', 'Demo sub 2'].map((name) =>
      page.getByRole('treeitem', { name }).element().querySelector(`[data-testid="${LIST}-level-line"]`)!
    );
    expect(lines.every(Boolean)).toBe(true);

    const [first, second] = lines.map((line) => line.getBoundingClientRect());
    expect(first.right).toBe(second.right);
    expect(second.top).toBeLessThanOrEqual(first.bottom);
  });

  it('carries the tree semantics that its rows claim, not a plain list one', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).toBeVisible();

    // "aria-expanded" and "aria-level" belong to a treeitem; an option carries
    // neither, so the rows and the box holding them have to agree.
    await expect.element(page.getByRole('tree')).toBeVisible();
    expect(document.querySelectorAll('[role="listbox"], [role="option"]')).toHaveLength(0);

    const child = page.getByRole('treeitem', { name: 'Demo sub 1' });
    await expect.element(child).toHaveAttribute('aria-level', '2');
    await expect.element(child).toHaveAttribute('aria-posinset', '1');
    await expect.element(child).toHaveAttribute('aria-setsize', '2');
  });

  it('leaves a flat search a plain list', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));

    await userEvent.click(page.getByLabelText('Assignee'));
    await expect.element(page.getByRole('option', { name: 'Elif Yildiz' })).toBeVisible();

    // Nothing about people is nested, so nothing claims to be.
    await expect.element(page.getByRole('option', { name: 'Elif Yildiz' })).not.toHaveAttribute('aria-level');
  });

  it('keeps the level lines out of the way until the tree is pointed at', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).toBeVisible();

    const line = page.getByRole('treeitem', { name: 'Demo sub 1' })
      .element().querySelector(`[data-testid="${LIST}-level-line"]`)!;
    const drawn = () => getComputedStyle(line, '::before').opacity;

    // Away from the tree: the search box is part of the dropdown, not of it.
    await userEvent.hover(page.getByTestId(SEARCH));
    await expect.poll(drawn).toBe('0');

    await userEvent.hover(page.getByRole('treeitem', { name: 'Demo sub 1' }));
    await expect.poll(drawn).toBe('1');
  });

  it('answers the pointer on a fold marker, and only where there is one', async () => {
    await openProjectPicker();

    const foldable = page.getByTestId(`${LIST}-twisty-0`).element();
    const resting = getComputedStyle(foldable).backgroundColor;
    await userEvent.hover(page.getByTestId(`${LIST}-twisty-0`));
    await expect.poll(() => getComputedStyle(foldable).backgroundColor).not.toBe(resting);

    // The second row has nothing under it: its slot is empty and stays plain,
    // the row underneath it being the only thing there is to click.
    const leaf = page.getByTestId(`${LIST}-twisty-1`).element();
    await userEvent.hover(page.getByTestId(`${LIST}-twisty-1`));
    expect(getComputedStyle(leaf).backgroundColor).toBe('rgba(0, 0, 0, 0)');
  });

  it('keeps Enter to itself when it has nothing to pick', async () => {
    await openProjectPicker();
    await userEvent.fill(page.getByLabelText('Subject *'), 'Not meant to be created');
    await userEvent.click(page.getByLabelText(PROJECT_FIELD));
    await search('nothing matches this');
    await expect.element(page.getByText('No results')).toBeVisible();

    await userEvent.keyboard('{Enter}');

    // Left to the form, Enter in a text field submits it.
    await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
  });

  it('closes only itself on Escape, wherever the focus sits in it', async () => {
    await openProjectPicker();
    await userEvent.tab();
    await expect.element(page.getByTestId(`${LIST}-mode-all`)).toHaveFocus();

    await userEvent.keyboard('{Escape}');

    await expect.element(page.getByRole('tree')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
  });

  it('leaves the arrow keys to the caret while a term is typed', async () => {
    await openProjectPicker();
    await search('demo');
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).toBeVisible();

    const input = page.getByTestId(SEARCH).element() as HTMLInputElement;
    expect(input.selectionStart).toBe(4);
    await userEvent.keyboard('{ArrowLeft}');

    // The tree does not eat the key: there is text to move through.
    expect(input.selectionStart).toBe(3);
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).toBeVisible();
  });

  it('keeps the fold markers live while a search is on', async () => {
    await openProjectPicker();
    await search('demo');
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).toBeVisible();

    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));

    // Folded away right here, not silently remembered for after the search.
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).not.toBeInTheDocument();
    expect(optionLabels()).toEqual(['Demo project']);
  });

  it('drags the list along as the keyboard walks past its edge', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).toBeVisible();

    const tree = page.getByRole('tree').element();
    tree.scrollTop = 0;
    await userEvent.keyboard('{ArrowDown}{ArrowDown}{ArrowDown}');

    const last = page.getByRole('treeitem', { name: 'Scrum project' }).element().getBoundingClientRect();
    const popover = page.getByTestId(`${LIST}-popover`).element().getBoundingClientRect();
    expect(last.bottom).toBeLessThanOrEqual(popover.bottom + 1);
  });

  it('asks the API for the order of the nested set', async () => {
    const sorts:(string | null)[] = [];
    const record = ({ request }:{ request:Request }) => {
      if (request.url.includes('/available_projects')) {
        sorts.push(new URL(request.url).searchParams.get('sortBy'));
      }
    };
    worker.events.on('request:start', record);

    try {
      await openProjectPicker();
      expect(sorts.length).toBeGreaterThan(0);
      expect(sorts.every((sort) => sort === '[["lft","asc"]]')).toBe(true);
    } finally {
      worker.events.removeListener('request:start', record);
    }
  });

  it('leaves the plain searches unordered, having no hierarchy to read', async () => {
    const sorts:(string | null)[] = [];
    const record = ({ request }:{ request:Request }) => {
      if (request.url.includes('/available_assignees')) {
        sorts.push(new URL(request.url).searchParams.get('sortBy'));
      }
    };
    worker.events.on('request:start', record);

    try {
      await openProjectPicker();
      await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));

      await userEvent.click(page.getByLabelText('Assignee'));
      await expect.element(page.getByRole('option', { name: 'Elif Yildiz' })).toBeVisible();
      expect(sorts.every((sort) => sort === null)).toBe(true);
    } finally {
      worker.events.removeListener('request:start', record);
    }
  });

  it('unfolds the whole tree for a search, so nothing it found stays hidden', async () => {
    await openProjectPicker();
    await search('demo');

    await expect.element(page.getByRole('treeitem', { name: 'Scrum project' })).not.toBeInTheDocument();

    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).toBeVisible();
    expect(optionLabels()).toEqual(['Demo project', 'Demo sub 1', 'Demo sub 2']);
  });

  it('leaves a subproject at the left edge once its parent is searched away', async () => {
    await openProjectPicker();
    const rootLeft = labelLeft('Demo project');

    await search('sub 1');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();

    expect(labelLeft('Demo sub 1')).toBe(rootLeft);
  });

  it('marks a favorite with a star, and lists it only once', async () => {
    await openProjectPicker();

    expect(optionLabels().filter((label) => label === 'Scrum project')).toHaveLength(1);
    expect(page.getByRole('treeitem', { name: 'Scrum project' }).element().querySelectorAll('svg')).toHaveLength(1);
    expect(page.getByRole('treeitem', { name: 'Demo project' }).element().querySelectorAll('svg')).toHaveLength(1);
  });

  it('narrows the list to the favorites, and back to all of them', async () => {
    await openProjectPicker();

    await userEvent.click(page.getByTestId(`${LIST}-mode-favored`));
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();
    expect(optionLabels()).toEqual(['Scrum project']);

    await userEvent.click(page.getByTestId(`${LIST}-mode-all`));
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
    expect(optionLabels()).toEqual(['Demo project', 'Scrum project']);
  });

  it('keeps the favorites narrowed while a search runs on top of them', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByTestId(`${LIST}-mode-favored`));
    await expect.element(page.getByRole('treeitem', { name: 'Scrum project' })).toBeVisible();

    await search('demo');
    await expect.element(page.getByRole('treeitem', { name: 'Scrum project' })).not.toBeInTheDocument();
    expect(optionLabels()).toEqual([]);
  });

  it('offers no filter where nothing can be favored', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));

    await userEvent.click(page.getByLabelText('Assignee'));
    await expect.element(page.getByRole('option', { name: 'Elif Yildiz' })).toBeVisible();
    await expect.element(page.getByTestId('op-bn-create-wp-assignee-list-mode-favored')).not.toBeInTheDocument();
  });

  it('asks for a hundred projects rather than a first handful', async () => {
    const pageSizes:(string | null)[] = [];
    const record = ({ request }:{ request:Request }) => {
      if (request.url.includes('/available_projects')) {
        pageSizes.push(new URL(request.url).searchParams.get('pageSize'));
      }
    };
    worker.events.on('request:start', record);

    try {
      await openProjectPicker();
      expect(pageSizes.length).toBeGreaterThan(0);
      expect(pageSizes.every((size) => size === '100')).toBe(true);
    } finally {
      worker.events.removeListener('request:start', record);
    }
  });

  it('closes and reopens the list from the arrows on the right', async () => {
    await openProjectPicker();

    await userEvent.click(page.getByTestId(TOGGLE));
    await expect.element(page.getByRole('tree')).not.toBeInTheDocument();

    await userEvent.click(page.getByTestId(TOGGLE));
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
  });

  it('empties the search from the clear button, and lists everything again', async () => {
    await openProjectPicker();
    await search('scrum');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();

    await userEvent.click(page.getByTestId(CLEAR));

    await expect.element(page.getByTestId(SEARCH)).toHaveValue('');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
  });

  it('stands the clear button in the search box before anything is typed', async () => {
    await openProjectPicker();

    await expect.element(page.getByTestId(CLEAR)).toBeVisible();
    // Inside the search box, not out on the field itself.
    expect(page.getByTestId(SEARCH).element().parentElement!.contains(page.getByTestId(CLEAR).element()))
      .toBe(true);
  });

  it('opens on the project already picked, marked and reached first', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Scrum project' }));

    await userEvent.click(page.getByLabelText(PROJECT_FIELD));

    const picked = page.getByRole('treeitem', { name: 'Scrum project' });
    await expect.element(picked).toHaveAttribute('aria-selected', 'true');
    expect(getComputedStyle(picked.element()).backgroundColor)
      .not.toBe(getComputedStyle(page.getByRole('treeitem', { name: 'Demo project' }).element()).backgroundColor);
  });

  it('keeps the pick marked once the focus is walked off it', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Scrum project' }));
    await userEvent.click(page.getByLabelText(PROJECT_FIELD));

    await userEvent.keyboard('{ArrowUp}');

    const picked = page.getByRole('treeitem', { name: 'Scrum project' });
    await expect.element(picked).toHaveAttribute('aria-selected', 'false');

    const marked = getComputedStyle(picked.element()).backgroundColor;
    const focused = getComputedStyle(page.getByRole('treeitem', { name: 'Demo project' }).element()).backgroundColor;
    expect(marked).not.toBe('rgba(0, 0, 0, 0)');
    expect(marked).not.toBe(focused);
  });

  it('answers the pointer on its buttons with a background alone', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));
    await userEvent.click(page.getByLabelText(PROJECT_FIELD));

    const crosses = [CLEAR, `${LIST}-deselect`]
      .map((testId) => page.getByTestId(testId).element().querySelector('svg')!.getBoundingClientRect());
    expect(crosses[0].width).toBe(crosses[1].width);
    expect(crosses[0].height).toBe(crosses[1].height);

    for (const testId of [CLEAR, `${LIST}-deselect`]) {
      const button = page.getByTestId(testId).element();
      const resting = getComputedStyle(button);
      const [restingColor, restingBackground] = [resting.color, resting.backgroundColor];

      await userEvent.hover(page.getByTestId(testId));

      await expect.poll(() => getComputedStyle(button).backgroundColor).not.toBe(restingBackground);
      expect(getComputedStyle(button).color).toBe(restingColor);
    }
  });

  it('keeps the field naming the pick, and searches in the dropdown instead', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));

    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('Demo project');
    await expect.element(page.getByRole('tree')).not.toBeInTheDocument();

    await userEvent.click(page.getByLabelText(PROJECT_FIELD));

    await expect.element(page.getByTestId(SEARCH)).toHaveValue('');
    expect(optionLabels()).toEqual(['Demo project', 'Scrum project']);
  });

  it('forgets a search once the dropdown is left', async () => {
    await openProjectPicker();
    await search('scrum');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();

    await userEvent.click(page.getByTestId(TOGGLE));
    await userEvent.click(page.getByTestId(TOGGLE));

    await expect.element(page.getByTestId(SEARCH)).toHaveValue('');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
  });

  it('lets the picked project go from its own row in the list', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));
    await expect.element(page.getByLabelText('Type *')).toBeVisible();

    await userEvent.click(page.getByLabelText(PROJECT_FIELD));
    await expect.element(page.getByTestId(`${LIST}-deselect`)).toBeVisible();
    expect(document.querySelectorAll(`[data-testid="${LIST}-deselect"]`)).toHaveLength(1);

    await userEvent.click(page.getByTestId(`${LIST}-deselect`));

    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('');
    await expect.element(page.getByLabelText('Type *')).not.toBeInTheDocument();
  });

  it('marks no row as picked while nothing is picked', async () => {
    await openProjectPicker();

    await expect.element(page.getByTestId(`${LIST}-deselect`)).not.toBeInTheDocument();
  });

  it('stays open when its own chrome is clicked', async () => {
    await openProjectPicker();

    const popover = page.getByTestId(`${LIST}-popover`).element().getBoundingClientRect();
    await userEvent.click(page.getByTestId(`${LIST}-popover`), {
      position: { x: 4, y: Math.round(popover.height) - 3 },
    });

    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
  });

  it('unfolds down to a project picked out of a search', async () => {
    await openProjectPicker();
    await search('sub 2');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo sub 2' }));

    await userEvent.click(page.getByLabelText(PROJECT_FIELD));

    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 2' })).toBeVisible();
    await expect.element(page.getByTestId(`${LIST}-deselect`)).toBeVisible();
  });

  it('reaches the filters with the keyboard', async () => {
    await openProjectPicker();

    await userEvent.tab();
    await expect.element(page.getByTestId(`${LIST}-mode-all`)).toHaveFocus();
    await userEvent.tab();
    await expect.element(page.getByTestId(`${LIST}-mode-favored`)).toHaveFocus();

    await userEvent.keyboard('{Enter}');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();
  });

  it('says it is loading while a filter is being answered', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByTestId(`${LIST}-mode-favored`));
    await search('demo');
    await expect.element(page.getByText('No results')).toBeVisible();

    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/available_projects', async () => {
        await new Promise((resolve) => setTimeout(resolve, 400));
        return HttpResponse.json({ _embedded: { elements: [] } });
      })
    );

    await userEvent.click(page.getByTestId(`${LIST}-mode-all`));

    await expect.element(page.getByText('Loading…')).toBeVisible();
  });

  it('sizes the search box for its own trailing button, not for the field one', async () => {
    await openProjectPicker();

    expect(getComputedStyle(page.getByTestId(SEARCH).element()).paddingRight).toBe('32px');
    expect(getComputedStyle(page.getByLabelText(PROJECT_FIELD).element()).paddingRight).toBe('32px');
  });

  it('keeps working where the API says nothing about favorites or nesting', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/available_projects', () =>
        HttpResponse.json({
          _embedded: {
            elements: [{ id: 1, name: 'Demo project', _links: { self: { href: '/api/v3/projects/1' } } }],
          },
        })
      )
    );

    await openProjectPicker();

    expect(optionLabels()).toEqual(['Demo project']);
    expect(page.getByRole('treeitem', { name: 'Demo project' }).element().querySelectorAll('svg')).toHaveLength(0);
  });
});
