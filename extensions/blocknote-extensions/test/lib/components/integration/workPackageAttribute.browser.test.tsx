import { describe, it, expect, vi, afterEach } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { renderEditor } from '../../../helpers/renderEditor';
import { worker } from '../../../mocks/browser';
import { requestsDuring } from '../../../helpers/requestHelpers';
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
  const el = document.querySelector('[contenteditable]');
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
    expect(getComputedStyle(chip()).backgroundColor).toBe('rgb(221, 244, 255)');
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
