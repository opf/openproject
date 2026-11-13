import { describe, it, expect, vi, afterEach } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { http } from 'msw';
import '@blocknote/core/fonts/inter.css';
import { TextSelection } from 'prosemirror-state';
import { renderEditor, renderEditorInShadowDom } from '../../../helpers/renderEditor';
import type { AnyEditor } from '../../../../lib/editorTypes';
import { worker } from '../../../mocks/browser';
import { requestedWorkPackageIds, workPackageCollection } from '../../../mocks/handlers';
import { loadUnavailableWorkPackages, requestsDuring } from '../../../helpers/requestHelpers';
import { mockAttributeWorkPackage } from '../../../mocks/workPackageAttributes';
import {
  buildWorkPackageAttributeExternalDOM,
  computeWorkPackageAttributeExternalData,
} from '../../../../lib/components/WorkPackageAttribute/externalHtml';

const props = { wpid: '123', displayId: 'PROJ-123', attribute: 'Content owner', display: 'both' };

interface InlineNode { type:string, props?:Record<string, unknown> }

function attributeProps(editor:{ document:{ content?:InlineNode[] }[] }) {
  return editor.document
    .flatMap((block) => block.content ?? [])
    .filter((node) => node.type === 'openProjectWorkPackageAttributeInline')
    .map((node) => node.props);
}

function pasteHtml(html:string, plain:string) {
  const el = document.querySelector('.bn-editor');
  if (!(el instanceof HTMLElement)) throw new Error('No [contenteditable] to paste into');
  const dt = new DataTransfer();
  dt.setData('text/html', html);
  dt.setData('text/plain', plain);
  el.dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true }));
}

afterEach(() => {
  worker.resetHandlers();
});

function renderAttribute(attribute:string, display:string, wpid = '321') {
  renderEditor({
    initialContent: [{
      type: 'paragraph',
      content: ['See ', { type: 'openProjectWorkPackageAttributeInline', props: { wpid, displayId: 'PROJ-321', attribute, display } }],
    }],
  });
}

function chip() {
  const element = document.querySelector('.op-bn-wp-attribute');
  if (!element) throw new Error('No attribute chip rendered');
  return element;
}

describe('Inline work package attribute', () => {
  it('shows the value of the attribute', async () => {
    renderAttribute('Content owner', 'value');

    await vi.waitFor(() => expect(chip().textContent).toBe('Jean Cérien, Hugo Martins'));
    expect(chip().getAttribute('title')).toBe('PROJ-321 · Redesign onboarding flow');
    expect(getComputedStyle(chip()).backgroundColor).toBe('rgb(255, 255, 255)');
    expect(getComputedStyle(chip()).boxShadow).toBe('rgb(209, 217, 224) 0px 0px 0px 1px inset');
  });

  it('is as tall as an inline work package beside it', async () => {
    renderEditor({
      initialContent: [{
        type: 'paragraph',
        content: [
          { type: 'openProjectWorkPackageInline', props: { wpid: '123', size: 's', displayId: '123' } },
          ' ',
          { type: 'openProjectWorkPackageAttributeInline', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'subject', display: 'both' } },
        ],
      }],
    });

    await vi.waitFor(() => expect(chip().textContent).toBe('Subject: Redesign onboarding flow'));
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    const height = (selector:string) => document.querySelector(selector)!.getBoundingClientRect().height;
    expect(height('.op-bn-wp-attribute')).toBeCloseTo(height('.op-bn-inline-wp-base'), 0);
  });

  it('shows a date in the date format of the user', async () => {
    renderAttribute('startDate', 'value');

    await vi.waitFor(() => expect(chip().textContent).toBe('14.09.2026'));
  });

  it('shows a date time in the formats and time zone of the user', async () => {
    renderAttribute('createdAt', 'value');

    await vi.waitFor(() => expect(chip().textContent).toBe('01.09.2026 22:30'));
  });

  it('shows the label of the attribute', async () => {
    renderAttribute('status', 'label');

    await vi.waitFor(() => expect(chip().textContent).toBe('Status'));
  });

  it('shows label and value', async () => {
    renderAttribute('status', 'both');

    await vi.waitFor(() => expect(chip().textContent).toBe('Status: In progress'));
  });

  it('loads a work package and its schema in a single request for all of its attributes', async () => {
    const attribute = (name:string) =>
      ({ type: 'openProjectWorkPackageAttributeInline', props: { wpid: '321', displayId: 'PROJ-321', attribute: name, display: 'value' } });

    const requested = await requestsDuring('/api/v3/work_packages', async () => {
      renderEditor({
        initialContent: [{ type: 'paragraph', content: [attribute('status'), ' ', attribute('assignee'), ' ', attribute('Content owner')] }],
      });
      await expect.element(page.getByText('Mira Hofmann')).toBeVisible();
    });

    expect(requested).toHaveLength(1);
  });

  it('says so when the work package no longer has the attribute', async () => {
    renderAttribute('Designer', 'value');

    await vi.waitFor(() => expect(chip().textContent).toBe('Designer unavailable'));
  });

  it('says so when the work package cannot be seen', async () => {
    loadUnavailableWorkPackages(321);
    renderAttribute('status', 'value');

    await vi.waitFor(() => expect(chip().textContent).toBe('Work package unavailable: no permission'));
  });

  it('is recreated from its external HTML', async () => {
    let editor:any;
    renderEditor({ onEditor: (e) => { editor = e; } });
    await userEvent.click(page.getByRole('textbox'));

    const data = computeWorkPackageAttributeExternalData(props)!;
    pasteHtml(buildWorkPackageAttributeExternalDOM(data, document).outerHTML, data.text);

    await vi.waitFor(() => {
      expect(attributeProps(editor)).toEqual([props]);
    });
  });

  it('is copied on its own as its macro once clicked', async () => {
    renderAttribute('assignee', 'value');
    await expect.element(page.getByText('Mira Hofmann')).toBeVisible();

    let copied:string | undefined;
    const onCopy = (event:ClipboardEvent) => { copied = event.clipboardData?.getData('text/plain'); };
    window.addEventListener('copy', onCopy);

    await userEvent.click(page.getByText('Mira Hofmann'));
    await userEvent.keyboard('{Control>}c{/Control}');
    window.removeEventListener('copy', onCopy);

    expect(copied?.trim()).toBe('workPackageValue:PROJ-321:"assignee"');
  });
});

describe('Values of work package attributes', () => {
  const avatars = () => Array.from(chip().querySelectorAll<HTMLElement>('.op-bn-wp-attribute--avatar'));

  it('puts a dot in the color of the status before it', async () => {
    renderAttribute('status', 'value');

    await vi.waitFor(() => expect(chip().textContent).toBe('In progress'));
    await vi.waitFor(() => expect(getComputedStyle(chip().querySelector('.op-bn-wp-attribute--dot')!).backgroundColor).toBe('rgb(112, 133, 134)'));
  });

  it('puts a dot in the color of the priority before it', async () => {
    renderAttribute('priority', 'both');

    await vi.waitFor(() => expect(chip().textContent).toBe('Priority: High'));
    await vi.waitFor(() => expect(getComputedStyle(chip().querySelector('.op-bn-wp-attribute--dot')!).backgroundColor).toBe('rgb(202, 43, 25)'));
  });

  it('writes the type in capitals, as work packages show it', async () => {
    renderAttribute('type', 'value');

    await expect.element(page.getByTestId('op-bn-work-package--type')).toHaveTextContent('Feature');
    const type = page.getByTestId('op-bn-work-package--type').element();
    expect(getComputedStyle(type).textTransform).toBe('uppercase');
  });

  it('shows the picture of a user who has one', async () => {
    renderAttribute('assignee', 'value');

    await vi.waitFor(() => expect(chip().textContent).toBe('Mira Hofmann'));
    expect(avatars().map((avatar) => avatar.dataset.initials)).toEqual(['MH']);
    await vi.waitFor(() => expect(getComputedStyle(avatars()[0].querySelector('img')!).visibility).toBe('visible'));
  });

  // Pinned to Inter: under the test browser's default font the avatar clears the border either way.
  it('centers the picture inside the outline of the attribute', async () => {
    renderAttribute('assignee', 'both');
    await document.fonts.load('400 12px Inter');
    await document.fonts.load('600 14px Inter');
    expect(document.fonts.check('600 14px Inter')).toBe(true);
    await vi.waitFor(() => expect(avatars()).toHaveLength(1));

    const box = chip().getClientRects()[0];
    const avatar = avatars()[0].getBoundingClientRect();
    const above = avatar.top - box.top;
    const below = box.bottom - avatar.bottom;
    const border = 1;

    expect.soft(above, 'gap above the avatar').toBeGreaterThan(border);
    expect.soft(below, 'gap below the avatar').toBeGreaterThan(border);
    expect.soft(Math.abs(above - below), `${above}px above, ${below}px below`).toBeLessThan(0.25);
  });

  it('shows the initials of everyone without a picture', async () => {
    renderAttribute('Content owner', 'value');

    await vi.waitFor(() => expect(chip().textContent).toBe('Jean Cérien, Hugo Martins'));
    expect(avatars().map((avatar) => avatar.dataset.initials)).toEqual(['JC', 'HM']);
    expect(getComputedStyle(avatars()[0], '::before').content).toBe('"JC"');
    await vi.waitFor(() => expect(avatars()[0].querySelector('img')).not.toBeNull());
    expect(getComputedStyle(avatars()[0].querySelector('img')!).visibility).toBe('hidden');
  });

  it('decorates nothing when only the label is shown', async () => {
    renderAttribute('assignee', 'label');

    await vi.waitFor(() => expect(chip().textContent).toBe('Assignee'));
    expect(avatars()).toEqual([]);
  });
});

const SELECTION_RING = 'rgb(100, 160, 255) 0px 0px 0px 2px inset';

function selectInFirstParagraph(editor:AnyEditor, from:number, to:number) {
  editor.transact((tr) => {
    let start = -1;
    tr.doc.descendants((node, position) => {
      if (start === -1 && node.type.name === 'paragraph') start = position + 1;
      return start === -1;
    });
    tr.setSelection(TextSelection.create(tr.doc, start + from, start + to));
  });
}

describe('Work package attributes in a text selection', () => {
  // Safari reports a selection inside a shadow root as a selection on its host,
  // so the shadow DOM run guards against relying on the native selection.
  it.each([
    ['the light DOM', async (options:Parameters<typeof renderEditor>[0]) => { renderEditor(options); return document.body; }],
    ['a shadow DOM', async (options:Parameters<typeof renderEditor>[0]) => (await renderEditorInShadowDom(options)).shadowRoot],
  ])('outline inline chips while the selection covers them in %s', async (_, render) => {
    let editor:AnyEditor | undefined;
    const root = await render({
      onEditor: (instance) => { editor = instance; },
      initialContent: [{
        type: 'paragraph',
        content: [
          'See ',
          { type: 'openProjectWorkPackageAttributeInline', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'assignee', display: 'value' } },
          ' and ',
          { type: 'openProjectWorkPackageInline', props: { wpid: '123', displayId: 'PROJ-123', size: 'xxs' } },
        ],
      }],
    });
    const attribute = () => root.querySelector('.op-bn-wp-attribute')!;
    const workPackage = () => root.querySelector('.op-bn-inline-wp-base')!;
    const outlined = (element:Element) => getComputedStyle(element).boxShadow.includes(SELECTION_RING);
    await vi.waitFor(() => expect(root.textContent).toContain('Mira Hofmann'));
    editor!.focus();

    selectInFirstParagraph(editor!, 1, 6);
    await vi.waitFor(() => expect(outlined(attribute())).toBe(true));
    expect(outlined(workPackage())).toBe(false);

    selectInFirstParagraph(editor!, 1, 11);
    await vi.waitFor(() => expect(outlined(workPackage())).toBe(true));
    expect(outlined(attribute())).toBe(true);

    selectInFirstParagraph(editor!, 1, 3);
    await vi.waitFor(() => expect(outlined(attribute())).toBe(false));
    expect(outlined(workPackage())).toBe(false);
  });

  it('outline a long text while the selection covers it', async () => {
    renderEditor({
      initialContent: [
        { type: 'paragraph', content: 'First' },
        { type: 'openProjectWorkPackageAttributeBlock', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'description', display: 'value' } },
        { type: 'paragraph', content: 'Last' },
      ],
    });
    await expect.element(page.getByText('Kick-off')).toBeVisible();
    const frame = () => document.querySelector('.op-bn-wp-attribute-block')!;
    const unselected = getComputedStyle(frame()).boxShadow;

    await userEvent.click(page.getByText('First'));
    await userEvent.keyboard('{Home}{Shift>}{ArrowDown}{ArrowDown}{End}{/Shift}');
    await vi.waitFor(() => expect(getComputedStyle(frame()).boxShadow).not.toBe(unselected));
  });
});

describe('Long text work package attribute', () => {
  it('can be dragged to another place', async () => {
    let editor:{ document:{ type:string }[] } | undefined;
    renderEditor({
      onEditor: (instance) => { editor = instance; },
      initialContent: [
        { type: 'paragraph', content: 'First' },
        { type: 'openProjectWorkPackageAttributeBlock', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'description', display: 'value' } },
        { type: 'paragraph', content: 'Last' },
      ],
    });
    await expect.element(page.getByText('Kick-off')).toBeVisible();

    const frame = document.querySelector('.op-bn-wp-attribute-block')!;
    const dropTarget = page.getByText('Last').element().closest('[data-node-type="blockOuter"]')!;
    await userEvent.dragAndDrop(frame, dropTarget);

    await vi.waitFor(() => expect(editor!.document.map((block) => block.type))
      .toEqual(['paragraph', 'paragraph', 'openProjectWorkPackageAttributeBlock']));
    // BlockNote leaves its hidden drag preview until the next drag starts.
    document.querySelectorAll('.bn-drag-preview').forEach((preview) => preview.remove());
  });
});

describe('Work package attributes in a read-only editor', () => {
  const longText = { type: 'openProjectWorkPackageAttributeBlock', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'description', display: 'value' } };
  const inline = { type: 'openProjectWorkPackageAttributeInline', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'status', display: 'value' } };

  it('offer no menu to change what they show', async () => {
    renderEditor({ editable: false, initialContent: [{ type: 'paragraph', content: [inline] }, longText] });
    await expect.element(page.getByText('Kick-off')).toBeVisible();
    await expect.element(page.getByText('In progress')).toBeVisible();

    await userEvent.click(page.getByText('Kick-off'));
    await userEvent.click(page.getByText('In progress'));

    expect(document.querySelector('[data-testid="popover-content"]')).toBeNull();
  });
});

describe('Long text work package attribute from external HTML', () => {
  it('is recreated as a block rather than a paragraph of its macro', async () => {
    let editor:{ document:{ type:string, props?:Record<string, unknown> }[] } | undefined;
    renderEditor({ onEditor: (instance) => { editor = instance; } });
    await userEvent.click(page.getByRole('textbox'));

    const block = { wpid: '321', displayId: 'PROJ-321', attribute: 'description', display: 'both' };
    const data = computeWorkPackageAttributeExternalData(block, 'block')!;
    pasteHtml(buildWorkPackageAttributeExternalDOM(data, document).outerHTML, data.text);

    await vi.waitFor(() => expect(editor!.document.find((entry) => entry.type === 'openProjectWorkPackageAttributeBlock')?.props)
      .toEqual(block));
  });
});

describe('Size menu of a long text taller than the screen', () => {
  it('shows all its options on its own background', async () => {
    const longText = '<p>' + 'A long line of text. '.repeat(400) + '</p>';
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages', ({ request }) =>
        (requestedWorkPackageIds(request)
          ? workPackageCollection([{ ...mockAttributeWorkPackage, description: { format: 'markdown', raw: '', html: longText } }])
          : undefined))
    );
    renderEditor({
      initialContent: [
        { type: 'paragraph', content: 'Before' },
        { type: 'openProjectWorkPackageAttributeBlock', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'description', display: 'value' } },
      ],
    });
    await expect.element(page.getByText('A long line', { exact: false }).first()).toBeVisible();

    await userEvent.click(document.querySelector('.op-bn-wp-attribute-block')!);
    await userEvent.click(page.getByRole('menuitem', { name: /^Change size/ }));
    const menu = page.getByTestId('size-menu').element();
    const menuBox = menu.getBoundingClientRect();

    for (const option of Array.from(menu.querySelectorAll('[role="menuitemradio"]'))) {
      const box = option.getBoundingClientRect();
      expect(box.bottom).toBeLessThanOrEqual(menuBox.bottom);
    }
    expect(menu.scrollHeight).toBeLessThanOrEqual(menu.clientHeight);
  });
});

describe('Options of a work package attribute', () => {
  const inlineStatus = { type: 'openProjectWorkPackageAttributeInline', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'status', display: 'value' } };
  const longText = { type: 'openProjectWorkPackageAttributeBlock', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'description', display: 'value' } };

  it('look like the options of a work package', async () => {
    renderAttribute('status', 'value');
    await userEvent.click(page.getByRole('button', { name: 'In progress' }));

    const menu = page.getByRole('menu', { name: 'Options for Status of work package PROJ-321' });
    await expect.element(menu).toBeVisible();
    await expect.element(menu.getByRole('menuitem', { name: 'Open work package PROJ-321 in new tab' })).toHaveTextContent('Open PROJ-321');
    await expect.element(menu.getByRole('menuitem', { name: 'Change size: Value' })).toHaveTextContent('Value');
    await expect.element(menu.getByRole('menuitem', { name: 'Remove work package attribute' })).toHaveTextContent('Remove');
  });

  it('open the work package in a new tab', async () => {
    const openSpy = vi.spyOn(window, 'open').mockReturnValue(null);
    renderAttribute('status', 'value');
    await userEvent.click(page.getByRole('button', { name: 'In progress' }));

    await userEvent.click(page.getByRole('menuitem', { name: 'Open work package PROJ-321 in new tab' }));

    expect(openSpy).toHaveBeenCalledWith(expect.stringContaining('/wp/PROJ-321'), '_blank', 'noopener,noreferrer');
    openSpy.mockRestore();
  });

  it('switch what an inline attribute shows', async () => {
    let editor:any;
    renderEditor({
      onEditor: (instance) => { editor = instance; },
      initialContent: [{ type: 'paragraph', content: ['See ', inlineStatus] }],
    });
    await userEvent.click(page.getByRole('button', { name: 'In progress' }));

    await userEvent.click(page.getByRole('menuitem', { name: 'Change size: Value' }));
    await userEvent.click(page.getByRole('menuitemradio', { name: 'Label + value' }));

    await expect.element(page.getByRole('button', { name: 'Status: In progress' })).toBeVisible();
    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
    expect(attributeProps(editor)[0]).toMatchObject({ display: 'both' });
  });

  it('remove an inline attribute', async () => {
    let editor:any;
    renderEditor({
      onEditor: (instance) => { editor = instance; },
      initialContent: [{ type: 'paragraph', content: ['See ', inlineStatus] }],
    });
    await userEvent.click(page.getByRole('button', { name: 'In progress' }));

    await userEvent.click(page.getByRole('menuitem', { name: 'Remove work package attribute' }));

    await vi.waitFor(() => expect(attributeProps(editor)).toEqual([]));
    await expect.element(page.getByText('See')).toBeVisible();
    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
  });

  it('remove a long text', async () => {
    let editor:{ document:{ type:string }[] } | undefined;
    renderEditor({
      onEditor: (instance) => { editor = instance; },
      initialContent: [{ type: 'paragraph', content: 'Before' }, longText],
    });
    await expect.element(page.getByText('Kick-off')).toBeVisible();
    await userEvent.click(page.getByText('Kick-off'));

    await userEvent.click(page.getByRole('menuitem', { name: 'Remove work package attribute' }));

    await vi.waitFor(() => expect(editor!.document.map((block) => block.type)).not.toContain('openProjectWorkPackageAttributeBlock'));
  });
});
