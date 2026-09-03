import { afterEach, describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { recordFrames } from '../../../helpers/animationHelpers';
import { openCreateModal } from '../../../helpers/createWorkPackageHelpers';
import { requestsDuring } from '../../../helpers/requestHelpers';
import { worker } from '../../../mocks/browser';

afterEach(() => worker.resetHandlers());

const PROJECT_FIELD = 'Project *';
const LIST = 'op-bn-create-wp-project-list';
const TOGGLE = 'op-bn-create-wp-project-toggle';
const CLEAR = 'op-bn-create-wp-project-clear';
const HEADER = 'op-bn-create-wp-project-list-header';

async function openProjectPicker(firstProject = 'Demo project') {
  renderEditor();
  await openCreateModal();
  await userEvent.click(page.getByLabelText(PROJECT_FIELD));
  await expect.element(page.getByRole('treeitem', { name: firstProject })).toBeVisible();
}

function serveNestedProjects(children:number) {
  const parent = { href: '/api/v3/projects/100', title: 'Parent project' };

  worker.use(
    http.get('http://localhost:3000/api/v3/work_packages/available_projects', () =>
      HttpResponse.json({ _embedded: { elements: [
        { id: 100, name: 'Parent project', _links: { self: { href: parent.href } } },
        ...Array.from({ length: children }, (_, index) => ({
          id: 200 + index,
          name: `Child ${index + 1}`,
          _links: { self: { href: `/api/v3/projects/${200 + index}` }, ancestors: [parent] },
        })),
      ] } })
    )
  );
}

function serveManyProjects() {
  const parent = { href: '/api/v3/projects/100', title: 'Parent project' };
  const elements = [
    { id: 100, name: 'Parent project', _links: { self: { href: parent.href } } },
    ...Array.from({ length: 30 }, (_, index) => ({
      id: 200 + index,
      name: `Child project ${String(index + 1).padStart(2, '0')}`,
      _links: { self: { href: `/api/v3/projects/${200 + index}` }, ancestors: [parent] },
    })),
  ];

  worker.use(
    http.get('http://localhost:3000/api/v3/work_packages/available_projects', () =>
      HttpResponse.json({ _embedded: { elements } })
    )
  );
}

function search(term:string) {
  return userEvent.fill(page.getByLabelText(PROJECT_FIELD), term);
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

    // What the field says it opens has to agree with it too.
    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveAttribute('aria-haspopup', 'tree');

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

    // Away from the tree: the filters are part of the dropdown, not of it.
    await userEvent.hover(page.getByTestId(`${LIST}-mode-all`));
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

    const input = page.getByLabelText(PROJECT_FIELD).element() as HTMLInputElement;
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

  it('asks for one page of a hundred projects, and for no page after it', async () => {
    const asked = await requestsDuring('/available_projects', () => openProjectPicker());

    expect(asked).toHaveLength(1);
    const params = new URL(asked[0]).searchParams;
    expect(params.get('pageSize')).toBe('100');
    expect(params.get('offset')).toBe(null);
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

    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
  });

  it('lists everything again from what it has, asking for none of it twice', async () => {
    await openProjectPicker();
    await search('scrum');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();

    const asked = await requestsDuring('/available_projects', async () => {
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

    const asked = await requestsDuring('/available_projects', async () => {
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

    const asked = await requestsDuring('/available_projects', async () => {
      await openCreateModal();
      await userEvent.click(page.getByLabelText(PROJECT_FIELD));
      await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();
    });

    expect(asked).toEqual([]);
  });

  it('searches once for a term, and answers it from memory the next time', async () => {
    await openProjectPicker();

    const first = await requestsDuring('/available_projects', async () => {
      await search('scrum');
      await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();
    });
    expect(first).toHaveLength(1);

    await userEvent.click(page.getByTestId(CLEAR));
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).toBeVisible();

    const again = await requestsDuring('/available_projects', async () => {
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

    const asked = await requestsDuring('/available_projects', async () => {
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

  it('holds a cross at the end of the field once there is something to clear', async () => {
    await openProjectPicker();

    await expect.element(page.getByTestId(CLEAR)).not.toBeInTheDocument();

    await search('scrum');
    await expect.element(page.getByTestId(CLEAR)).toBeVisible();
  });

  it('lets the pick go from the cross at the end of the field', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));
    await expect.element(page.getByLabelText('Type *')).toBeVisible();
    await expect.element(page.getByTestId(CLEAR)).toBeVisible();

    await userEvent.click(page.getByTestId(CLEAR));

    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('');
    await expect.element(page.getByLabelText('Type *')).not.toBeInTheDocument();
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
    await expect.element(page.getByLabelText(PROJECT_FIELD))
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

  it('searches in the one field that names the pick, the dropdown holding none', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));

    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('Demo project');
    await expect.element(page.getByRole('tree')).not.toBeInTheDocument();

    await userEvent.click(page.getByLabelText(PROJECT_FIELD));
    expect(page.getByTestId(`${LIST}-popover`).element().querySelectorAll('input')).toHaveLength(0);
    expect(optionLabels()).toEqual(['Demo project', 'Scrum project']);

    await search('scrum');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();

    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('scrum');
    expect(optionLabels()).toEqual(['Scrum project']);
  });

  it('starts a fresh term when a key is typed on the field naming the pick', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));
    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('Demo project');

    await userEvent.keyboard('s');

    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('s');
    await expect.element(page.getByRole('treeitem', { name: 'Scrum project' })).toBeVisible();
  });

  it('lets the pick go from the keyboard alone', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));
    await expect.element(page.getByLabelText('Type *')).toBeVisible();

    await userEvent.keyboard('{Backspace}');

    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('');
    await expect.element(page.getByLabelText('Type *')).not.toBeInTheDocument();
  });

  it('names the pick as a hint while the field is searched in', async () => {
    await openProjectPicker();
    await userEvent.click(page.getByRole('treeitem', { name: 'Demo project' }));

    await userEvent.click(page.getByLabelText(PROJECT_FIELD));

    const field = page.getByLabelText(PROJECT_FIELD).element();
    expect(field.getAttribute('placeholder')).toBe('Demo project');
    expect(getComputedStyle(field, '::placeholder').opacity).toBe('1');
  });

  it('forgets a search once the dropdown is left', async () => {
    await openProjectPicker();
    await search('scrum');
    await expect.element(page.getByRole('treeitem', { name: 'Demo project' })).not.toBeInTheDocument();

    await userEvent.click(page.getByTestId(TOGGLE));
    await userEvent.click(page.getByTestId(TOGGLE));

    await expect.element(page.getByLabelText(PROJECT_FIELD)).toHaveValue('');
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

    await expect.poll(() => page.getByTestId(`${LIST}-popover`).element().getAnimations().length).toBe(0);
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

  it('sizes the field for the trailing actions it carries', async () => {
    await openProjectPicker();

    expect(getComputedStyle(page.getByLabelText(PROJECT_FIELD).element()).paddingRight).toBe('32px');

    await search('scrum');

    expect(getComputedStyle(page.getByLabelText(PROJECT_FIELD).element()).paddingRight).toBe('56px');
  });

  it('keeps the rows walking under the header hidden by it, fold markers and all', async () => {
    serveManyProjects();
    await openProjectPicker('Parent project');
    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
    await expect.element(page.getByRole('treeitem', { name: 'Child project 01' })).toBeVisible();

    const popover = page.getByTestId(`${LIST}-popover`).element();
    const header = page.getByTestId(HEADER).element();
    const marker = page.getByTestId(`${LIST}-twisty-0`).element().querySelector('svg')!;

    // Scrolled until the fold marker of the first row sits under the header.
    const spot = header.getBoundingClientRect().bottom - 4;
    const markerCenter = () => {
      const bounds = marker.getBoundingClientRect();
      return bounds.top + bounds.height / 2;
    };
    popover.scrollTop += markerCenter() - spot;

    const bounds = marker.getBoundingClientRect();
    expect(markerCenter()).toBeGreaterThan(header.getBoundingClientRect().top);
    expect(markerCenter()).toBeLessThan(header.getBoundingClientRect().bottom);

    const painted = document.elementFromPoint(bounds.left + bounds.width / 2, markerCenter());
    expect(header.contains(painted)).toBe(true);
  });

  it('leaves no strip above the header for the rows to show through', async () => {
    serveManyProjects();
    await openProjectPicker('Parent project');
    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
    await expect.element(page.getByRole('treeitem', { name: 'Child project 01' })).toBeVisible();

    const popover = page.getByTestId(`${LIST}-popover`).element();
    const header = page.getByTestId(HEADER).element();
    popover.scrollTop = 40;

    const bounds = popover.getBoundingClientRect();
    // Just inside the top border, where the list's own padding used to leave a gap.
    const painted = document.elementFromPoint(bounds.left + bounds.width / 2, bounds.top + 2);
    expect(header.contains(painted)).toBe(true);
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
  it('rolls away from the height it had when closed part way through an unfold', async () => {
    serveNestedProjects(5);
    await openProjectPicker('Parent project');

    const popover = () => document.querySelector<HTMLElement>(`[data-testid="${LIST}-popover"]`);
    await expect.poll(() => popover()?.getAnimations().length).toBe(0);
    const settled = popover()!.getBoundingClientRect().height;

    const recorded = recordFrames<number>(() => {
      const list = popover();
      return list ? list.getBoundingClientRect().height : null;
    });

    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
    await new Promise((resolve) => { setTimeout(resolve, 60); });
    await userEvent.keyboard('{Escape}');
    await expect.poll(popover).toBeNull();
    recorded.stop();

    expect(Math.max(...recorded.frames)).toBeGreaterThan(settled);

    const steps = recorded.frames
      .slice(1)
      .map((height, index) => height - recorded.frames[index])
      .filter((step) => step > 0);

    expect(steps.length).toBeGreaterThan(2);
    expect(Math.max(...steps)).toBe(steps[0]);
  });

  it('crosses to its new height when a parent unfolds rather than jumping', async () => {
    serveNestedProjects(4);
    await openProjectPicker('Parent project');

    const popover = () => document.querySelector<HTMLElement>(`[data-testid="${LIST}-popover"]`);
    await expect.poll(() => popover()?.getAnimations().length).toBe(0);

    const before = popover()!.getBoundingClientRect().height;
    const recorded = recordFrames<number>(() => {
      const list = popover();
      return list ? list.getBoundingClientRect().height : null;
    });

    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
    await expect.element(page.getByRole('treeitem', { name: 'Child 1' })).toBeVisible();
    await expect.poll(() => popover()?.getAnimations().length).toBe(0);
    recorded.stop();

    const after = popover()!.getBoundingClientRect().height;
    expect(after).toBeGreaterThan(before);

    expect(new Set(recorded.frames).size).toBeGreaterThan(2);
    expect(Math.min(...recorded.frames)).toBe(before);
    expect(Math.max(...recorded.frames)).toBeLessThanOrEqual(after);
  });

});
