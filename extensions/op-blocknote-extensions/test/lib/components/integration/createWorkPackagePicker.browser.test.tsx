import { afterEach, describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { recordFrames } from '../../../helpers/animationHelpers';
import {
  colorChannelsOf,
  fillRequiredFields,
  openCreateModal,
  pickProject,
  selectOptionNamed,
} from '../../../helpers/createWorkPackageHelpers';
import { worker } from '../../../mocks/browser';

afterEach(() => worker.resetHandlers());

const TYPE_LIST = '[data-testid="op-bn-create-wp-type-list-popover"]';
const typeOption = (index:number) => `op-bn-create-wp-type-list-option-${index}`;
const MANY_TYPES = ['Alpha', 'Bravo', 'Charlie', 'Delta', 'Echo', 'Foxtrot',
  'Golf', 'Hotel', 'India', 'Juliett', 'Kilo', 'Lima'];
const SHARED_PREFIXES = ['In progress', 'New', 'In specification', 'In development'];
// Embedded, not linked: only this shape carries ancestors through the schema reader.
const ANCESTRY = [
  { name: 'Parent', _links: { self: { href: '/api/v3/types/1' } } },
  {
    name: 'Child',
    _links: {
      self: { href: '/api/v3/types/2' },
      ancestors: [{ href: '/api/v3/types/1' }],
    },
  },
];

interface Cover {
  top:number;
  bottom:number;
}

const typeList = ():HTMLElement | null => document.querySelector(TYPE_LIST);

// Two frames, so React has rendered what the dispatch asked for.
const settle = () => new Promise((resolve) => {
  requestAnimationFrame(() => { requestAnimationFrame(() => resolve(null)); });
});

function coverOf(clipPath:string):Cover | null {
  const match = /^inset\(([^)]+)\)$/.exec(clipPath);
  if (!match) return null;

  const sides = match[1].trim().split(/\s+/).map((side) => Number.parseFloat(side));
  return { top: sides[0], bottom: sides.length >= 3 ? sides[2] : sides[0] };
}

const recordCover = () => recordFrames<Cover>(() => {
  const list = typeList();
  return list ? coverOf(getComputedStyle(list).clipPath) : null;
});

function formOfferingTypes(titles:string[]) {
  return http.post('http://localhost:3000/api/v3/work_packages/form', () => HttpResponse.json({
    _type: 'Form',
    _embedded: {
      payload: { subject: null, _links: { project: { href: '/api/v3/projects/1' } } },
      schema: {
        _type: 'Schema',
        subject: { type: 'String', name: 'Subject', required: true, hasDefault: false, writable: true },
        project: {
          type: 'Project', name: 'Project', required: true, hasDefault: false, writable: true, location: '_links',
          _links: { allowedValues: { href: '/api/v3/work_packages/available_projects' } },
        },
        type: {
          type: 'Type', name: 'Type', required: true, hasDefault: false, writable: true, location: '_links',
          _links: { allowedValues: titles.map((title, index) => ({ href: `/api/v3/types/${index + 1}`, title })) },
        },
      },
      validationErrors: {},
    },
  }));
}

async function openModalOnTypeField():Promise<HTMLInputElement> {
  renderEditor();
  await openCreateModal();
  await pickProject();
  await expect.element(page.getByLabelText('Type *')).toBeVisible();

  return page.getByLabelText('Type *').element() as HTMLInputElement;
}

describe('Create work package - the list a fixed set of values is picked from', () => {
  it('rolls open downwards from the field and shut upwards back to it', async () => {
    const trigger = await openModalOnTypeField();

    const opening = recordCover();
    await userEvent.click(page.getByLabelText('Type *'));
    await expect.element(page.getByRole('option', { name: 'Task' })).toBeVisible();
    await expect.poll(() => typeList()?.getAnimations().length).toBe(0);
    opening.stop();

    const height = typeList()!.getBoundingClientRect().height;
    const uncovering = opening.frames.map(({ bottom }) => bottom);

    expect(opening.frames.every(({ top }) => top === 0)).toBe(true);
    expect(new Set(uncovering).size).toBeGreaterThan(2);
    expect(Math.max(...uncovering)).toBeGreaterThan(height / 2);
    expect(uncovering).toEqual([...uncovering].sort((a, b) => b - a));
    expect(getComputedStyle(typeList()!).clipPath).toBe('none');

    const closing = recordCover();
    await userEvent.keyboard('{Escape}');
    await expect.poll(typeList).toBeNull();
    closing.stop();

    const covering = closing.frames.map(({ bottom }) => bottom);

    expect(closing.frames.every(({ top }) => top === 0)).toBe(true);
    expect(new Set(covering).size).toBeGreaterThan(2);
    expect(Math.max(...covering)).toBeGreaterThan(height / 2);
    expect(covering).toEqual([...covering].sort((a, b) => a - b));

    await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
    expect(trigger.getAttribute('aria-expanded')).toBe('false');
  });

  it('is walked and picked from with the keyboard alone', async () => {
    const trigger = await openModalOnTypeField();
    const activeOption = () => trigger.getAttribute('aria-activedescendant');

    trigger.focus();
    expect(trigger.getAttribute('aria-expanded')).toBe('false');

    await userEvent.keyboard('{ArrowDown}');
    await expect.poll(activeOption).toBe(typeOption(0));

    await userEvent.keyboard('{ArrowDown}');
    await expect.poll(activeOption).toBe(typeOption(1));

    await userEvent.keyboard('{Enter}');
    await expect.poll(() => trigger.value).toBe('Bug');
    expect(trigger.getAttribute('aria-expanded')).toBe('false');
  });

  it('keeps up with keys pressed faster than it can render', async () => {
    const trigger = await openModalOnTypeField();
    trigger.focus();

    for (const key of ['ArrowDown', 'ArrowDown', 'Enter']) {
      trigger.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true }));
    }

    await expect.poll(() => trigger.value).toBe('Bug');
  });

  it('walks to the option a typed letter names, without picking it', async () => {
    const trigger = await openModalOnTypeField();

    trigger.focus();
    await userEvent.keyboard('m');

    await expect.poll(() => trigger.getAttribute('aria-activedescendant')).toBe(typeOption(2));
    expect(trigger.value).toBe('Task');

    await userEvent.keyboard('{Enter}');
    await expect.poll(() => trigger.value).toBe('Milestone');
  });

  it('searches on everything typed, not on the last letter alone', async () => {
    worker.use(formOfferingTypes(SHARED_PREFIXES));
    const trigger = await openModalOnTypeField();

    trigger.focus();
    await userEvent.keyboard('in d');

    await expect.poll(() => trigger.getAttribute('aria-activedescendant')).toBe(typeOption(3));

    await userEvent.keyboard('{Enter}');
    await expect.poll(() => trigger.value).toBe('In development');
  });

  it('walks the options that share a letter when that letter is pressed again', async () => {
    worker.use(formOfferingTypes(SHARED_PREFIXES));
    const trigger = await openModalOnTypeField();
    const activeOption = () => trigger.getAttribute('aria-activedescendant');

    trigger.focus();
    await userEvent.keyboard('i');
    await expect.poll(activeOption).toBe(typeOption(0));

    await userEvent.keyboard('i');
    await expect.poll(activeOption).toBe(typeOption(2));

    await userEvent.keyboard('i');
    await expect.poll(activeOption).toBe(typeOption(3));

    await userEvent.keyboard('i');
    await expect.poll(activeOption).toBe(typeOption(0));
  });

  it('does not let a resting pointer take the highlight off the keyboard', async () => {
    const trigger = await openModalOnTypeField();
    const activeOption = () => trigger.getAttribute('aria-activedescendant');

    trigger.focus();
    await userEvent.keyboard('{ArrowDown}{ArrowDown}');
    await expect.poll(activeOption).toBe(typeOption(1));

    const resting = page.getByRole('option', { name: 'Task' }).element();
    resting.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
    await settle();
    expect(activeOption()).toBe(typeOption(1));

    resting.dispatchEvent(new MouseEvent('mousemove', { bubbles: true }));
    await settle();
    expect(activeOption()).toBe(typeOption(0));
  });

  it('offers every value it was given, whatever the API says descends from what', async () => {
    worker.use(http.post('http://localhost:3000/api/v3/work_packages/form', () => HttpResponse.json({
      _type: 'Form',
      _embedded: {
        payload: { subject: null, _links: { project: { href: '/api/v3/projects/1' } } },
        schema: {
          _type: 'Schema',
          subject: { type: 'String', name: 'Subject', required: true, hasDefault: false, writable: true },
          project: {
            type: 'Project', name: 'Project', required: true, hasDefault: false, writable: true, location: '_links',
            _links: { allowedValues: { href: '/api/v3/work_packages/available_projects' } },
          },
          type: {
            type: 'Type', name: 'Type', required: true, hasDefault: false, writable: true, location: '_links',
            _embedded: { allowedValues: ANCESTRY },
          },
        },
        validationErrors: {},
      },
    })));

    await openModalOnTypeField();
    await userEvent.click(page.getByLabelText('Type *'));

    await expect.element(page.getByRole('option', { name: 'Parent' })).toBeVisible();
    await expect.element(page.getByRole('option', { name: 'Child' })).toBeVisible();
  });

  it('keeps the option the keyboard is on in view', async () => {
    worker.use(formOfferingTypes(MANY_TYPES));
    const trigger = await openModalOnTypeField();

    trigger.focus();
    await userEvent.keyboard('{ArrowDown}');
    await expect.element(page.getByRole('option', { name: 'Alpha' })).toBeVisible();

    const list = typeList()!;
    expect(list.scrollHeight).toBeGreaterThan(list.clientHeight);

    await userEvent.keyboard('{End}');
    await expect.poll(() => trigger.getAttribute('aria-activedescendant'))
      .toBe(typeOption(MANY_TYPES.length - 1));

    const walked = document.getElementById(trigger.getAttribute('aria-activedescendant')!)!;
    expect(list.scrollTop).toBeGreaterThan(0);
    expect(walked.getBoundingClientRect().bottom).toBeLessThanOrEqual(list.getBoundingClientRect().bottom);
  });

  it('is picked from and not typed into', async () => {
    const trigger = await openModalOnTypeField();

    expect(trigger.readOnly).toBe(true);

    await userEvent.click(page.getByLabelText('Type *'));
    await expect.element(page.getByRole('option', { name: 'Task' })).toBeVisible();
    await userEvent.keyboard('Something else');

    expect(trigger.value).not.toContain('Something');
  });

  it('keeps its prompt in place while the list is open', async () => {
    const trigger = await openModalOnTypeField();

    expect(getComputedStyle(trigger, '::placeholder').opacity).toBe('1');

    await userEvent.click(page.getByLabelText('Type *'));
    await expect.element(page.getByRole('option', { name: 'Task' })).toBeVisible();

    expect(getComputedStyle(trigger, '::placeholder').opacity).toBe('1');
  });

  it('marks every type in the list with the colour of that type', async () => {
    await openModalOnTypeField();

    await userEvent.click(page.getByLabelText('Type *'));
    await expect.element(page.getByRole('option', { name: 'Task' })).toBeVisible();

    const dotOf = (type:string) => page
      .getByRole('option', { name: type })
      .element()
      .querySelector('[data-testid="create-wp-option-color"]')!;

    await expect.poll(() => colorChannelsOf(dotOf('Task'))).toEqual(['211', '84', '0']);
    expect(colorChannelsOf(dotOf('Bug'))).toEqual(['39', '174', '96']);
  });

  it('lines the colour of an option up with the colour of the pick', async () => {
    await openModalOnTypeField();
    await selectOptionNamed('Type *', 'Task');

    const picked = page.getByTestId('create-wp-type-color').element().getBoundingClientRect();

    await userEvent.click(page.getByLabelText('Type *'));
    await expect.element(page.getByRole('option', { name: 'Bug' })).toBeVisible();

    const listed = typeList()!
      .querySelector('[data-testid="create-wp-option-color"]')!
      .getBoundingClientRect();

    expect(Math.round(listed.left)).toBe(Math.round(picked.left));
    expect(Math.round(listed.width)).toBe(Math.round(picked.width));
  });

  it('leaves the lists of every other field uncoloured', async () => {
    renderEditor();
    await openCreateModal();
    await fillRequiredFields('Fix the header alignment');

    await userEvent.click(page.getByLabelText('Department *'));
    await expect.element(page.getByRole('option', { name: 'Design' })).toBeVisible();

    expect(document.querySelector('[data-testid="op-bn-create-wp-customField3-list-popover"] [data-testid="create-wp-option-color"]'))
      .toBeNull();
  });
});
