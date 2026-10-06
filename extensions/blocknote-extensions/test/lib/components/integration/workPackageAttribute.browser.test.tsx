import { describe, it, expect, vi, afterEach } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { renderEditor } from '../../../helpers/renderEditor';
import { worker } from '../../../mocks/browser';
import { requestsDuring } from '../../../helpers/requestHelpers';
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
    .filter((node) => node.type === 'openProjectWorkPackageAttribute')
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
      content: ['See ', { type: 'openProjectWorkPackageAttribute', props: { wpid, displayId: 'PROJ-321', attribute, display } }],
    }],
  });
}

function chip() {
  const element = document.querySelector('.op-bn-wp-attribute');
  if (!element) throw new Error('No attribute chip rendered');
  return element;
}

describe('Work package attribute chip', () => {
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
          { type: 'openProjectWorkPackageAttribute', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'subject', display: 'both' } },
        ],
      }],
    });

    await vi.waitFor(() => expect(chip().textContent).toBe('Subject: Redesign onboarding flow'));
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    const height = (selector:string) => document.querySelector(selector)!.getBoundingClientRect().height;
    expect(height('.op-bn-wp-attribute')).toBeCloseTo(height('.op-bn-inline-wp-base'), 0);
  });

  it('shows the label of the attribute', async () => {
    renderAttribute('status', 'label');

    await vi.waitFor(() => expect(chip().textContent).toBe('Status'));
  });

  it('shows label and value', async () => {
    renderAttribute('status', 'both');

    await vi.waitFor(() => expect(chip().textContent).toBe('Status: In progress'));
  });

  it('loads a work package once for all of its WP attributes', async () => {
    const attribute = (name:string) =>
      ({ type: 'openProjectWorkPackageAttribute', props: { wpid: '321', displayId: 'PROJ-321', attribute: name, display: 'value' } });

    const requested = await requestsDuring('/api/v3/work_packages/321', async () => {
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
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/321', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 }))
    );
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
  const inline = { type: 'openProjectWorkPackageAttribute', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'status', display: 'value' } };

  it('offer no menu to change what they show', async () => {
    renderEditor({ editable: false, initialContent: [{ type: 'paragraph', content: [inline] }, longText] });
    await expect.element(page.getByText('Kick-off')).toBeVisible();
    await expect.element(page.getByText('In progress')).toBeVisible();

    await userEvent.click(page.getByText('Kick-off'));
    await userEvent.click(page.getByText('In progress'));

    expect(document.querySelector('[data-testid="attribute-display-menu"]')).toBeNull();
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

describe('Display menu of a long text taller than the screen', () => {
  it('shows all its options on its own background', async () => {
    const longText = '<p>' + 'A long line of text. '.repeat(400) + '</p>';
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/321', () =>
        HttpResponse.json({ ...mockAttributeWorkPackage, description: { format: 'markdown', raw: '', html: longText } }))
    );
    renderEditor({
      initialContent: [
        { type: 'paragraph', content: 'Before' },
        { type: 'openProjectWorkPackageAttributeBlock', props: { wpid: '321', displayId: 'PROJ-321', attribute: 'description', display: 'value' } },
      ],
    });
    await expect.element(page.getByText('A long line', { exact: false }).first()).toBeVisible();

    await userEvent.click(document.querySelector('.op-bn-wp-attribute-block')!);
    const menu = page.getByTestId('attribute-display-menu').element();
    const menuBox = menu.getBoundingClientRect();

    for (const option of Array.from(menu.querySelectorAll('[role="menuitemradio"]'))) {
      const box = option.getBoundingClientRect();
      expect(box.bottom).toBeLessThanOrEqual(menuBox.bottom);
    }
    expect(menu.scrollHeight).toBeLessThanOrEqual(menu.clientHeight);
  });
});
