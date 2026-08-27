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

async function openProjectPicker(firstProject = 'Demo project') {
  renderEditor();
  await openCreateModal();
  await userEvent.click(page.getByLabelText(PROJECT_FIELD));
  await expect.element(page.getByRole('treeitem', { name: firstProject })).toBeVisible();
}

/*  Stands in for ALLOWED_VALUES_PAGE_SIZE, so that a listing runs over its
    pages without a hundred projects having to be invented for it.  */
const PAGE_SIZE = 2;

const alpha = { href: '/api/v3/projects/11', title: 'Alpha' };
const beta = { href: '/api/v3/projects/14', title: 'Beta' };

const pagedProjects = [
  { id: 11, name: 'Alpha', _links: { self: { href: alpha.href } } },
  { id: 12, name: 'Alpha sub 1', _links: { self: { href: '/api/v3/projects/12' }, ancestors: [alpha] } },
  { id: 13, name: 'Alpha sub 2', _links: { self: { href: '/api/v3/projects/13' }, ancestors: [alpha] } },
  { id: 14, name: 'Beta', _links: { self: { href: beta.href } } },
  { id: 15, name: 'Beta sub 1', _links: { self: { href: '/api/v3/projects/15' }, ancestors: [beta] } },
];

function servePagedProjects({ overlapping = false } = {}):number[] {
  const pagesAsked:number[] = [];

  worker.use(
    http.get('http://localhost:3000/api/v3/work_packages/available_projects', ({ request }) => {
      const asked = Number(new URL(request.url).searchParams.get('offset') ?? '1');
      pagesAsked.push(asked);

      const start = Math.max(0, (asked - 1) * PAGE_SIZE - (overlapping && asked > 1 ? 1 : 0));
      const elements = pagedProjects.slice(start, start + PAGE_SIZE);

      return HttpResponse.json({
        total: pagedProjects.length,
        count: elements.length,
        pageSize: PAGE_SIZE,
        offset: asked,
        _embedded: { elements },
      });
    })
  );

  return pagesAsked;
}

async function unfoldPagedProjects() {
  await openProjectPicker('Alpha');
  await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
  await expect.element(page.getByRole('treeitem', { name: 'Alpha sub 1' })).toBeVisible();
  await userEvent.click(page.getByTestId(`${LIST}-twisty-3`));
  await expect.element(page.getByRole('treeitem', { name: 'Beta sub 1' })).toBeVisible();
}

function search(term:string) {
  return userEvent.fill(page.getByTestId(SEARCH), term);
}

async function projectRequestsDuring(act:() => Promise<void>):Promise<string[]> {
  const asked:string[] = [];
  const record = ({ request }:{ request:Request }) => {
    if (request.url.includes('/available_projects')) asked.push(request.url);
  };

  worker.events.on('request:start', record);
  try {
    await act();
  } finally {
    worker.events.removeListener('request:start', record);
  }

  return asked;
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

    // What the field and its search say they open has to agree with it too.
    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveAttribute('aria-haspopup', 'tree');
    await expect.element(page.getByTestId(SEARCH)).toHaveAttribute('aria-haspopup', 'tree');

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
    const resting = getComputedStyle(foldable, '::before').backgroundColor;
    await userEvent.hover(page.getByTestId(`${LIST}-twisty-0`));
    await expect.poll(() => getComputedStyle(foldable, '::before').backgroundColor).not.toBe(resting);

    // The second row has nothing under it: its slot is empty and stays plain,
    // the row underneath it being the only thing there is to click.
    const leaf = page.getByTestId(`${LIST}-twisty-1`).element();
    await userEvent.hover(page.getByTestId(`${LIST}-twisty-1`));
    expect(getComputedStyle(leaf, '::before').backgroundColor).toBe('rgba(0, 0, 0, 0)');
  });

  it('answers for its fold marker over the whole left edge of the row', async () => {
    await openProjectPicker();

    const row = page.getByRole('treeitem', { name: 'Demo project' }).element().getBoundingClientRect();
    const twisty = page.getByTestId(`${LIST}-twisty-0`).element();
    const marker = twisty.querySelector('svg')!.getBoundingClientRect();

    expect(marker.width).toBe(12);
    const shown = getComputedStyle(twisty, '::before');
    const slot = twisty.getBoundingClientRect();
    expect(parseFloat(shown.height)).toBeCloseTo(row.height, 2);
    expect(shown.left).toBe(shown.right);
    expect(slot.left + parseFloat(shown.left)).toBeCloseTo(row.left, 2);
    expect(labelLeft('Demo project')).toBeGreaterThan(slot.right - parseFloat(shown.right));

    const clickAt = (x:number, y:number) => userEvent.click(
      page.getByRole('treeitem', { name: 'Demo project' }),
      { position: { x, y } }
    );

    await clickAt(1, Math.round(row.height / 2));
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).toBeVisible();

    await clickAt(4, 2);
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).not.toBeInTheDocument();

    await clickAt(4, Math.round(row.height) - 3);
    await expect.element(page.getByRole('treeitem', { name: 'Demo sub 1' })).toBeVisible();

    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('');
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

  it('leaves the first row reachable when a key comes before the options do', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/available_projects', async () => {
        await new Promise((resolve) => setTimeout(resolve, 500));
        return HttpResponse.json({
          _embedded: {
            elements: [{ id: 1, name: 'Demo project', _links: { self: { href: '/api/v3/projects/1' } } }],
          },
        });
      })
    );

    renderEditor();
    await openCreateModal();
    await userEvent.click(page.getByLabelText(PROJECT_FIELD));
    // Nothing is listed yet, so there is no row below to walk to.
    await userEvent.keyboard('{ArrowDown}');

    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
    await userEvent.keyboard('{Enter}');

    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('Demo project');
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
    const asked = await projectRequestsDuring(() => openProjectPicker());
    const pageSizes = asked.map((url) => new URL(url).searchParams.get('pageSize'));

    expect(pageSizes.length).toBeGreaterThan(0);
    expect(pageSizes.every((size) => size === '100')).toBe(true);
  });

  it('walks the pages of a listing that does not fit into one', async () => {
    const pagesAsked = servePagedProjects();

    await unfoldPagedProjects();

    expect(optionLabels()).toEqual(['Alpha', 'Alpha sub 1', 'Alpha sub 2', 'Beta', 'Beta sub 1']);
    expect([...new Set(pagesAsked)]).toEqual([1, 2, 3]);
  });

  it('lists a project once where a page repeats what the one before it had', async () => {
    servePagedProjects({ overlapping: true });

    await unfoldPagedProjects();

    const labels = optionLabels();
    expect(labels).toEqual(['Alpha', 'Alpha sub 1', 'Alpha sub 2', 'Beta', 'Beta sub 1']);
    expect(new Set(labels).size).toBe(labels.length);
  });

  it('keeps a subtree whole where the page boundary cuts through it', async () => {
    servePagedProjects();

    await openProjectPicker('Alpha');
    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));

    await expect.element(page.getByRole('treeitem', { name: 'Alpha sub 2' })).toBeVisible();
    expect(labelLeft('Alpha sub 2')).toBe(labelLeft('Alpha sub 1'));

    const cutOff = page.getByRole('treeitem', { name: 'Alpha sub 2' });
    await expect.element(cutOff).toHaveAttribute('aria-level', '2');
    await expect.element(cutOff).toHaveAttribute('aria-posinset', '2');
    await expect.element(cutOff).toHaveAttribute('aria-setsize', '2');
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

  it('lists everything again from what it has, asking for none of it twice', async () => {
    await openProjectPicker();
    await search('scrum');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();

    const asked = await projectRequestsDuring(async () => {
      await userEvent.click(page.getByTestId(CLEAR));
      await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
    });

    expect(asked).toEqual([]);
    expect(optionLabels()).toEqual(['Demo project', 'Scrum project']);
  });

  it('reopens on the listing it was given, without asking for it again', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByTestId(TOGGLE));
    await expect.element(page.getByRole('tree')).not.toBeInTheDocument();

    const asked = await projectRequestsDuring(async () => {
      await userEvent.click(page.getByTestId(TOGGLE));
      await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
      // The list stands there from memory at once; an ask would follow the debounce.
      await new Promise((resolve) => setTimeout(resolve, 600));
    });

    expect(asked).toEqual([]);
  });

  it('opens a second create modal on the listing the first one was given', async () => {
    await openProjectPicker();
    await userEvent.keyboard('{Escape}');
    await expect.element(page.getByRole('tree')).not.toBeInTheDocument();

    await userEvent.click(page.getByRole('button', { name: 'Cancel' }));
    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();

    const asked = await projectRequestsDuring(async () => {
      await openCreateModal();
      await userEvent.click(page.getByLabelText(PROJECT_FIELD));
      await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
    });

    expect(asked).toEqual([]);
  });

  it('searches once for a term, and answers it from memory the next time', async () => {
    await openProjectPicker();

    const first = await projectRequestsDuring(async () => {
      await search('scrum');
      await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();
    });
    expect(first).toHaveLength(1);

    await userEvent.click(page.getByTestId(CLEAR));
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();

    const again = await projectRequestsDuring(async () => {
      await search('scrum');
      await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();
    });
    expect(again).toEqual([]);
  });

  it('comes back to the favorites it has already been given', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByTestId(`${LIST}-mode-favored`));
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();
    await userEvent.click(page.getByTestId(`${LIST}-mode-all`));
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();

    const asked = await projectRequestsDuring(async () => {
      await userEvent.click(page.getByTestId(`${LIST}-mode-favored`));
      await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();
    });

    expect(asked).toEqual([]);
    expect(optionLabels()).toEqual(['Scrum project']);
  });

  it('keeps nothing of a listing it was refused, and asks for it again', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/available_projects', () =>
        new HttpResponse(null, { status: 500 }))
    );

    renderEditor();
    await openCreateModal();
    await userEvent.click(page.getByLabelText(PROJECT_FIELD));
    await expect.element(page.getByText('No results')).toBeVisible();

    worker.resetHandlers();
    await userEvent.click(page.getByTestId(TOGGLE));
    await userEvent.click(page.getByTestId(TOGGLE));

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

    // The pick is what is selected; the row walked onto is named by
    // aria-activedescendant instead.
    const picked = page.getByRole('treeitem', { name: 'Scrum project' });
    const walkedOnto = page.getByRole('treeitem', { name: 'Demo project' });
    await expect.element(picked).toHaveAttribute('aria-selected', 'true');
    await expect.element(walkedOnto).toHaveAttribute('aria-selected', 'false');
    await expect.element(page.getByTestId(SEARCH))
      .toHaveAttribute('aria-activedescendant', walkedOnto.element().id);

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

    for (const [testId, painted] of [[CLEAR, ''], [`${LIST}-deselect`, '::before']] as const) {
      const button = page.getByTestId(testId).element();
      const restingColor = getComputedStyle(button).color;
      const background = () => getComputedStyle(button, painted || undefined).backgroundColor;
      const resting = background();

      await userEvent.hover(page.getByTestId(testId));

      await expect.poll(background).not.toBe(resting);
      expect(getComputedStyle(button).color).toBe(restingColor);
    }
  });

  it('answers for the cross of a row as it does for its fold marker', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));
    await userEvent.click(page.getByLabelText(PROJECT_FIELD));

    const row = page.getByRole('treeitem', { name: 'Demo project' }).element().getBoundingClientRect();
    const cross = page.getByTestId(`${LIST}-deselect`).element();
    const shown = getComputedStyle(cross, '::before');

    expect(parseFloat(shown.height)).toBeCloseTo(row.height, 2);
    expect(shown.left).toBe(shown.right);
    expect(cross.querySelector('svg')!.getBoundingClientRect().height).toBe(14);
    expect(cross.getBoundingClientRect().right - parseFloat(shown.right)).toBeCloseTo(row.right, 2);
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
