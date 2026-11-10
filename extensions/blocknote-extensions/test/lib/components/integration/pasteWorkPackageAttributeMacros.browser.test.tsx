import { describe, it, expect, vi, afterEach } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { renderEditor } from '../../../helpers/renderEditor';
import { openEditorAndType } from '../../../helpers/editorHelpers';
import { worker } from '../../../mocks/browser';
import { mockAttributeWorkPackage } from '../../../mocks/workPackageAttributes';
import { mockWorkPackage } from '../../../mocks/handlers';
import { computeWorkPackageAttributeExternalData } from '../../../../lib/components/WorkPackageAttribute/externalHtml';

interface Node { type:string, text?:string, props?:Record<string, unknown>, content?:Node[] }
interface Editor { document:Node[] }

const ATTRIBUTE = 'openProjectWorkPackageAttributeInline';
const ATTRIBUTE_BLOCK = 'openProjectWorkPackageAttributeBlock';

// CKEditor keeps attribute macros as plain text, so that is what it copies.
function pasteFromCKEditor(text:string) {
  const editable = document.querySelector('.bn-editor');
  if (!(editable instanceof HTMLElement)) throw new Error('No [contenteditable] to paste into');
  const data = new DataTransfer();
  data.setData('text/html', text.split('\n').map((line) => `<p>${line.replace(/"/g, '&quot;')}</p>`).join(''));
  data.setData('text/plain', text);
  editable.dispatchEvent(new ClipboardEvent('paste', { clipboardData: data, bubbles: true, cancelable: true }));
}

async function renderEmptyEditor(text = '') {
  let editor:Editor | undefined;
  renderEditor({ onEditor: (instance) => { editor = instance; } });
  if (text) await openEditorAndType(text);
  else await userEvent.click(page.getByRole('textbox'));
  return () => editor!;
}

function inlineContent(editor:Editor):Node[] {
  return editor.document.flatMap((block) => block.content ?? []);
}

function attributes(editor:Editor) {
  return inlineContent(editor).filter((node) => node.type === ATTRIBUTE).map((node) => node.props);
}

function textOf(nodes:Node[]):string {
  return nodes.map((node) => (node.type === 'text' ? node.text : `[${node.type}]`)).join('');
}

function text(editor:Editor):string {
  return textOf(inlineContent(editor));
}

function blocks(editor:Editor):string[] {
  return editor.document.map((block) => (block.content ? textOf(block.content) : `[${block.type}]`));
}

function delayWorkPackageLoads() {
  let release = () => {};
  const released = new Promise<void>((resolve) => { release = resolve; });
  worker.use(http.get('http://localhost:3000/api/v3/work_packages', async () => { await released; }));
  return release;
}

afterEach(() => {
  worker.resetHandlers();
});

describe('Pasting work package attribute macros from CKEditor', () => {
  it('turns a value macro with an id into an attribute', async () => {
    const editor = await renderEmptyEditor();

    pasteFromCKEditor('workPackageValue:321:assignee');

    await vi.waitFor(() => expect(attributes(editor())).toEqual([
      { wpid: '321', displayId: 'PROJ-321', attribute: 'assignee', display: 'value' },
    ]));
    await expect.element(page.getByText('Mira Hofmann')).toBeVisible();
  });

  it('turns a label macro with a semantic identifier into an attribute', async () => {
    const editor = await renderEmptyEditor();

    pasteFromCKEditor('workPackageLabel:PROJ-321:assignee');

    await vi.waitFor(() => expect(attributes(editor())).toEqual([
      { wpid: '321', displayId: 'PROJ-321', attribute: 'assignee', display: 'label' },
    ]));
    await expect.element(page.getByText('Assignee')).toBeVisible();
  });

  it.each([
    ['Value', 'value'],
    ['Label', 'label'],
  ])('finds the work package of a subject in a %s macro and copies it back with its id', async (kind, display) => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages', ({ request }) => (
        (new URL(request.url).searchParams.get('filters') ?? '').includes('typeahead')
          ? HttpResponse.json({ _embedded: { elements: [mockWorkPackage, mockAttributeWorkPackage] } })
          : undefined
      )),
    );
    const editor = await renderEmptyEditor();

    pasteFromCKEditor(`workPackage${kind}:"Redesign onboarding flow":assignee`);

    await vi.waitFor(() => expect(attributes(editor())).toHaveLength(1));
    const [attribute] = attributes(editor()) as [Record<string, string>];
    expect(attribute).toEqual({ wpid: '321', displayId: 'PROJ-321', attribute: 'assignee', display });
    expect(computeWorkPackageAttributeExternalData(attribute)!.text).toBe(`workPackage${kind}:PROJ-321:"assignee"`);
  });

  it('turns the label and value of one attribute into a single attribute showing both', async () => {
    const editor = await renderEmptyEditor();

    pasteFromCKEditor('workPackageLabel:321:"Content owner": workPackageValue:321:"Content owner"');

    await vi.waitFor(() => expect(attributes(editor())).toEqual([
      { wpid: '321', displayId: 'PROJ-321', attribute: 'Content owner', display: 'both' },
    ]));
  });

  it('keeps the surrounding text and the macros it cannot resolve', async () => {
    const editor = await renderEmptyEditor('Before ');

    pasteFromCKEditor('owner workPackageValue:321:assignee and workPackageValue:321:unknown here');

    await vi.waitFor(() => expect(text(editor())).toBe(
      `Before owner [${ATTRIBUTE}] and workPackageValue:321:unknown here`
    ));
  });

  it('turns a long text macro into a block', async () => {
    const editor = await renderEmptyEditor();

    pasteFromCKEditor('workPackageValue:321:description');

    await vi.waitFor(() => expect(editor().document.find((block) => block.type === ATTRIBUTE_BLOCK)?.props)
      .toEqual({ wpid: '321', displayId: 'PROJ-321', attribute: 'description', display: 'value' }));
    await expect.element(page.getByText('Kick-off')).toBeVisible();
  });

  it('leaves a macro without a work package as text', async () => {
    const editor = await renderEmptyEditor();

    pasteFromCKEditor('workPackageValue:assignee');

    await vi.waitFor(() => expect(text(editor())).toBe('workPackageValue:assignee'));
    expect(attributes(editor())).toEqual([]);
  });

  it('converts the macros of every pasted paragraph', async () => {
    const editor = await renderEmptyEditor();

    pasteFromCKEditor('Owner workPackageValue:321:assignee\nworkPackageLabel:321:status here');

    await vi.waitFor(() => expect(blocks(editor()).slice(0, 2)).toEqual([
      `Owner [${ATTRIBUTE}]`,
      `[${ATTRIBUTE}] here`,
    ]));
  });

  it('splits the line around a long text, keeping the reading order', async () => {
    const editor = await renderEmptyEditor();

    pasteFromCKEditor('Before workPackageValue:321:description after');

    await vi.waitFor(() => expect(blocks(editor()).slice(0, 3)).toEqual([
      'Before ',
      `[${ATTRIBUTE_BLOCK}]`,
      ' after',
    ]));
  });

  it('replaces the selected text with a long text', async () => {
    const editor = await renderEmptyEditor('Selected text');
    await userEvent.keyboard('{Shift>}{Home}{/Shift}');

    pasteFromCKEditor('workPackageValue:321:description');

    await vi.waitFor(() => expect(blocks(editor())[0]).toBe(`[${ATTRIBUTE_BLOCK}]`));
    expect(text(editor())).not.toContain('Selected text');
  });

  it('converts the macro where it was pasted, while the user keeps typing elsewhere', async () => {
    const release = delayWorkPackageLoads();
    const editor = await renderEmptyEditor('Hello ');

    pasteFromCKEditor('workPackageValue:321:assignee');
    await vi.waitFor(() => expect(text(editor())).toBe('Hello workPackageValue:321:assignee'));
    await userEvent.keyboard('{Home}Oh, ');
    release();

    await vi.waitFor(() => expect(text(editor())).toBe(`Oh, Hello [${ATTRIBUTE}]`));
  });

  it('keeps the caret in the text around a long text while it loads', async () => {
    const release = delayWorkPackageLoads();
    const editor = await renderEmptyEditor();

    pasteFromCKEditor('Before workPackageValue:321:description after');
    await vi.waitFor(() => expect(text(editor())).toBe('Before workPackageValue:321:description after'));
    await userEvent.keyboard('{Home}X');
    release();

    await vi.waitFor(() => expect(blocks(editor())[1]).toBe(`[${ATTRIBUTE_BLOCK}]`));
    await userEvent.keyboard('Y');
    expect(blocks(editor()).slice(0, 3)).toEqual(['XYBefore ', `[${ATTRIBUTE_BLOCK}]`, ' after']);
  });

  it('converts the macros pasted together with a work package link', async () => {
    const editor = await renderEmptyEditor();

    pasteFromCKEditor('See http://localhost:3000/wp/123 and workPackageValue:321:assignee');

    await vi.waitFor(() => expect(text(editor())).toBe(`See [openProjectWorkPackageInline] and [${ATTRIBUTE}]`));
  });

  describe('in tables', () => {
    const cells = () => [...document.querySelectorAll('td')];
    const cellTexts = () => cells().map((cell) => cell.textContent);
    const attributeCells = () => cells().map((cell) => cell.querySelector('.op-bn-wp-attribute') !== null);

    function pasteTableFromCKEditor(rows:string[][]) {
      const editable = document.querySelector('.bn-editor');
      if (!(editable instanceof HTMLElement)) throw new Error('No [contenteditable] to paste into');
      const html = `<table><tbody>${rows.map((row) => `<tr>${row.map((cell) => `<td>${cell}</td>`).join('')}</tr>`).join('')}</tbody></table>`;
      const data = new DataTransfer();
      data.setData('text/html', html);
      data.setData('text/plain', rows.map((row) => row.join('\t')).join('\n'));
      editable.dispatchEvent(new ClipboardEvent('paste', { clipboardData: data, bubbles: true, cancelable: true }));
    }

    function renderTable(cellsOfRow:string[]) {
      renderEditor({
        initialContent: [
          { type: 'table', content: { type: 'tableContent', rows: [{ cells: cellsOfRow }] } },
          { type: 'paragraph' },
        ],
      });
    }

    it('converts the macros of a pasted table', async () => {
      await renderEmptyEditor();

      pasteTableFromCKEditor([['workPackageValue:321:status', 'Owner workPackageValue:321:assignee']]);

      await vi.waitFor(() => expect(attributeCells()).toEqual([true, true]));
      expect(cellTexts()).toEqual(['In progress', 'Owner Mira Hofmann']);
    });

    it('converts a macro pasted into a cell, leaving the other cells alone', async () => {
      renderTable(['workPackageValue:321:status', '']);
      await expect.element(page.getByText('workPackageValue:321:status')).toBeVisible();

      await userEvent.click(cells()[1]);
      pasteFromCKEditor('workPackageValue:321:assignee');

      await vi.waitFor(() => expect(attributeCells()).toEqual([false, true]));
      expect(cellTexts()[0]).toBe('workPackageValue:321:status');
    });

    it('leaves a long text macro in a cell as text, since a cell cannot hold a block', async () => {
      renderTable(['', '']);
      await expect.element(page.getByRole('textbox')).toBeVisible();

      await userEvent.click(cells()[0]);
      pasteFromCKEditor('workPackageValue:321:description workPackageValue:321:status');

      await vi.waitFor(() => expect(cells()[0].querySelectorAll('.op-bn-wp-attribute')).toHaveLength(1));
      expect(cellTexts()[0]).toBe('workPackageValue:321:description In progress');
    });
  });
});
