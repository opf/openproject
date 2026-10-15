import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { cleanup } from 'vitest-browser-react';
import { BlockNoteSchema } from '@blocknote/core';
import { renderEditor } from '../../../helpers/renderEditor';
import { openProjectWorkPackageAttributeSpec } from '../../../../lib';
import { openEditorAndType, openWorkPackageAttributeDialog, SEARCH_PLACEHOLDER } from '../../../helpers/editorHelpers';
import { worker } from '../../../mocks/browser';
import { ATTRIBUTE_SCHEMA_HREF, mockAttributeWorkPackage, mockMilestoneWorkPackage } from '../../../mocks/workPackageAttributes';

interface InlineNode { type:string, props?:Record<string, unknown> }

let editor:{
  document:{ content?:InlineNode[] }[],
  insertBlocks:(blocks:unknown[], reference:unknown, placement:'before' | 'after') => void,
};

function attributeProps() {
  return editor.document
    .flatMap((block) => block.content ?? [])
    .filter((node) => node.type === 'openProjectWorkPackageAttribute')
    .map((node) => node.props);
}

const dialog = () => page.getByRole('dialog', { name: 'Insert work package attribute' });
const preview = () => page.getByTestId('insert-attribute-preview');
const insertButton = () => page.getByRole('button', { name: 'Insert', exact: true });

const workPackageField = () => page.getByRole('combobox', { name: 'Work package' });
const selectedWorkPackage = () => page.getByTestId('op-bn-wp-attribute-work-package-selected');

async function pickWorkPackage(term:string, subject:string) {
  await userEvent.fill(workPackageField(), term);
  await userEvent.click(page.getByRole('option', { name: new RegExp(subject) }));
}

async function pickAttribute(label:string) {
  await userEvent.click(page.getByRole('combobox', { name: 'Attribute' }));
  await userEvent.click(page.getByRole('option', { name: label }));
}

beforeEach(() => {
  worker.use(
    http.get('http://localhost:3000/api/v3/work_packages', () =>
      HttpResponse.json({ _embedded: { elements: [mockAttributeWorkPackage, mockMilestoneWorkPackage] } }))
  );
  renderEditor({ onEditor: (instance) => { editor = instance; } });
});

afterEach(() => {
  worker.resetHandlers();
});

describe('Insert work package attribute', () => {
  it('starts in the work package field', async () => {
    await openWorkPackageAttributeDialog();
    await expect.element(page.getByRole('option', { name: /Work package attribute/ })).not.toBeInTheDocument();
    expect(getComputedStyle(workPackageField().element(), '::placeholder').opacity).toBe('1');

    await vi.waitFor(() => expect(document.activeElement).toBe(workPackageField().element()));
    await userEvent.keyboard('Redesign');
    await expect.element(page.getByRole('option', { name: /Redesign onboarding flow/ })).toBeVisible();
  });

  it('offers attributes only once a work package is chosen', async () => {
    await openWorkPackageAttributeDialog();

    await expect.element(page.getByPlaceholder('Select a work package first')).toBeDisabled();
    const attributeStyle = getComputedStyle(page.getByPlaceholder('Select a work package first').element());
    expect(attributeStyle.cursor).toBe('not-allowed');
    expect(attributeStyle.backgroundColor).not.toBe(getComputedStyle(workPackageField().element()).backgroundColor);
    await expect.element(preview()).toHaveTextContent('Choose a work package and an attribute');
    await expect.element(insertButton()).toBeDisabled();
    expect(getComputedStyle(insertButton().element()).backgroundColor).toBe('rgb(239, 242, 245)');
  });

  it('draws its preview with the colors of the editor it was opened from', async () => {
    await openWorkPackageAttributeDialog();
    const editorStyle = getComputedStyle(document.querySelector('.bn-container')!);
    const dialogStyle = getComputedStyle(dialog().element());

    for (const name of ['--bn-colors-editor-background', '--bn-colors-editor-text']) {
      expect(editorStyle.getPropertyValue(name)).not.toBe('');
      expect(dialogStyle.getPropertyValue(name)).toBe(editorStyle.getPropertyValue(name));
    }
  });

  it('marks a single result when the keys move on from the hovered one', async () => {
    await openWorkPackageAttributeDialog();
    await userEvent.type(page.getByPlaceholder(SEARCH_PLACEHOLDER), 'e');
    await userEvent.hover(page.getByRole('option', { name: /Redesign onboarding flow/ }));
    await userEvent.keyboard('{ArrowDown}');

    const marked = Array.from(document.querySelectorAll('[role="option"]'))
      .filter((option) => getComputedStyle(option).backgroundColor !== 'rgba(0, 0, 0, 0)');
    expect(marked.map((option) => option.textContent)).toEqual([expect.stringContaining('Public beta')]);
  });

  it('keeps the reference of a result with a long subject on one line', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages', () =>
        HttpResponse.json({ _embedded: { elements: [{ ...mockAttributeWorkPackage, subject: 'Test'.repeat(40) }] } }))
    );
    await openWorkPackageAttributeDialog();
    await userEvent.type(page.getByPlaceholder(SEARCH_PLACEHOLDER), 'Test');
    await expect.element(page.getByRole('option').getByText('Feature')).toBeVisible();

    const type = page.getByRole('option').getByText('Feature').element();
    expect(type.getBoundingClientRect().width).toBeGreaterThan(type.getBoundingClientRect().height);
  });

  it('keeps a long subject within the dialog', async () => {
    const subject = 'Test'.repeat(40);
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages', () =>
        HttpResponse.json({ _embedded: { elements: [{ ...mockAttributeWorkPackage, subject }] } }))
    );
    await openWorkPackageAttributeDialog();
    await pickWorkPackage('Test', subject);
    await pickAttribute('Subject');

    const reference = selectedWorkPackage().getByText('Feature').element();
    expect(reference.getBoundingClientRect().width).toBeGreaterThan(reference.getBoundingClientRect().height);
    const layer = selectedWorkPackage().element();
    expect(layer.scrollWidth).toBeLessThanOrEqual(layer.clientWidth);
    const box = preview().element();
    expect(box.scrollWidth).toBeLessThanOrEqual(box.clientWidth);
  });

  it('inserts the chosen attribute with what it should show', async () => {
    await openWorkPackageAttributeDialog();
    await pickWorkPackage('Redesign', 'Redesign onboarding flow');
    await pickAttribute('Status');

    await expect.element(preview()).toHaveTextContent('In progress');
    expect(getComputedStyle(insertButton().element()).backgroundColor).toBe('rgb(9, 105, 218)');
    await userEvent.click(page.getByRole('radio', { name: 'Label + value' }));
    await expect.element(preview()).toHaveTextContent('Status: In progress');

    await userEvent.click(insertButton());

    await expect.element(dialog()).not.toBeInTheDocument();
    expect(attributeProps()).toEqual([
      { wpid: '321', displayId: 'PROJ-321', attribute: 'status', display: 'both' },
    ]);
    await expect.element(page.getByRole('button', { name: 'Status: In progress' })).toBeVisible();
  });

  it('references a custom field by its name', async () => {
    await openWorkPackageAttributeDialog();
    await pickWorkPackage('Redesign', 'Redesign onboarding flow');
    await pickAttribute('Content owner');
    await userEvent.click(insertButton());

    await vi.waitFor(() => expect(attributeProps()[0]).toMatchObject({ attribute: 'Content owner', display: 'value' }));
  });

  it('leaves nothing behind when cancelled', async () => {
    await openWorkPackageAttributeDialog();
    await userEvent.click(page.getByRole('button', { name: 'Cancel' }));

    await expect.element(dialog()).not.toBeInTheDocument();
    expect(editor.document[0].content).toEqual([]);
  });

  it('closes on Escape', async () => {
    await openWorkPackageAttributeDialog();
    await userEvent.keyboard('{Escape}');

    await expect.element(dialog()).not.toBeInTheDocument();
    expect(attributeProps()).toEqual([]);
  });

  it('says so when the attributes cannot be loaded, and loads them again on request', async () => {
    worker.use(
      http.get(`http://localhost:3000${ATTRIBUTE_SCHEMA_HREF}`, () => HttpResponse.json({}, { status: 500 }), { once: true })
    );
    await openWorkPackageAttributeDialog();
    await pickWorkPackage('Redesign', 'Redesign onboarding flow');

    await expect.element(page.getByRole('alert')).toHaveTextContent('The attributes of PROJ-321 could not be loaded. Try again');
    await expect.element(page.getByPlaceholder('Attributes unavailable')).toBeDisabled();

    await userEvent.click(page.getByRole('button', { name: 'Try again' }));

    await expect.element(page.getByRole('alert')).not.toBeInTheDocument();
    await pickAttribute('Status');
    await expect.element(preview()).toHaveTextContent('In progress');
  });

  it('says so when another work package lacks the chosen attribute', async () => {
    await openWorkPackageAttributeDialog();
    await pickWorkPackage('Redesign', 'Redesign onboarding flow');
    await pickAttribute('Finish date');

    await pickWorkPackage('beta', 'Public beta');

    await expect.element(page.getByText('"Finish date" is not available on PROJ-654. Choose another attribute.')).toBeVisible();
    await expect.element(insertButton()).toBeDisabled();
  });

  it('switches what an inserted attribute shows from its menu', async () => {
    await openWorkPackageAttributeDialog();
    await pickWorkPackage('Redesign', 'Redesign onboarding flow');
    await pickAttribute('Status');
    await userEvent.click(insertButton());

    await userEvent.click(page.getByRole('button', { name: 'In progress' }));
    const heading = getComputedStyle(page.getByTestId('attribute-display-menu').getByText('Show').element());
    expect(heading.opacity).toBe('1');
    expect(heading.color).toBe('rgb(89, 99, 110)');
    const check = page.getByRole('menuitemradio', { name: 'Value', exact: true }).element().querySelector('svg')!;
    expect(getComputedStyle(check).color).toBe('rgb(9, 105, 218)');
    await userEvent.click(page.getByRole('menuitemradio', { name: 'Label', exact: true }));

    await expect.element(page.getByRole('button', { name: 'Status', exact: true })).toBeVisible();
    await expect.element(page.getByTestId('attribute-display-menu')).not.toBeInTheDocument();
    expect(attributeProps()[0]).toMatchObject({ display: 'label' });
  });

  it('keeps the results in the list while it closes after a pick', async () => {
    await openWorkPackageAttributeDialog();
    await userEvent.fill(workPackageField(), 'Redesign');
    await userEvent.click(page.getByRole('option', { name: /Redesign onboarding flow/ }));

    expect(document.body.textContent).not.toContain('No results');
  });

  it('keeps the picked work package until another one is picked', async () => {
    await openWorkPackageAttributeDialog();
    await pickWorkPackage('Redesign', 'Redesign onboarding flow');
    await expect.element(workPackageField()).toHaveValue('');
    await expect.element(workPackageField()).toHaveAttribute('aria-describedby', 'op-bn-wp-attribute-work-package-selected');

    const marking = () => getComputedStyle(selectedWorkPackage().element().firstElementChild!).backgroundColor;
    const unmarked = marking();
    await userEvent.click(workPackageField());
    expect(marking()).not.toBe(unmarked);
    await userEvent.keyboard('be');
    await expect.element(selectedWorkPackage()).not.toBeInTheDocument();
    await expect.element(workPackageField()).toHaveValue('be');
    await userEvent.keyboard('{Escape}');
    await expect.element(selectedWorkPackage()).toHaveTextContent('PROJ-321FeatureRedesign onboarding flow');

    await userEvent.fill(workPackageField(), 'beta');
    await expect.element(page.getByRole('option', { name: /Public beta/ })).toBeVisible();
    await userEvent.keyboard('{Escape}');

    await expect.element(selectedWorkPackage()).toHaveTextContent('PROJ-321FeatureRedesign onboarding flow');
    await expect.element(dialog()).toBeVisible();

    await userEvent.fill(workPackageField(), 'beta');
    await userEvent.click(page.getByRole('radio', { name: 'Label', exact: true }));
    await expect.element(selectedWorkPackage()).toHaveTextContent('PROJ-321FeatureRedesign onboarding flow');
  });

  it('prefills the next invocation with the previous choice, which can be cleared', async () => {
    await openWorkPackageAttributeDialog();
    await pickWorkPackage('Redesign', 'Redesign onboarding flow');
    await pickAttribute('Status');
    await userEvent.click(page.getByRole('radio', { name: 'Label + value' }));
    await userEvent.click(insertButton());
    await expect.element(dialog()).not.toBeInTheDocument();

    await userEvent.keyboard('{End}');
    await openWorkPackageAttributeDialog();

    await expect.element(page.getByText('Prefilled with your last selection')).toBeVisible();
    await expect.element(selectedWorkPackage()).toHaveTextContent('PROJ-321FeatureRedesign onboarding flow');
    await expect.element(preview()).toHaveTextContent('Status: In progress');
    await expect.element(page.getByRole('radio', { name: 'Label + value' })).toHaveAttribute('aria-checked', 'true');

    await userEvent.click(page.getByRole('button', { name: 'Clear' }));

    await expect.element(page.getByText('Prefilled with your last selection')).not.toBeInTheDocument();
    await expect.element(selectedWorkPackage()).not.toBeInTheDocument();
    await expect.element(workPackageField()).toHaveValue('');
    await vi.waitFor(() => expect(document.activeElement).toBe(workPackageField().element()));
    await expect.element(page.getByRole('radio', { name: 'Value', exact: true })).toHaveAttribute('aria-checked', 'true');
    await expect.element(preview()).toHaveTextContent('Choose a work package and an attribute');
  });

  describe('long text', () => {
    function blocks() {
      return editor.document.map((block) => ({ type: (block as { type:string }).type, props: (block as { props?:unknown }).props }));
    }

    it('previews the long text as a block', async () => {
      await openWorkPackageAttributeDialog();
      await pickWorkPackage('Redesign', 'Redesign onboarding flow');
      await pickAttribute('Description');
      await userEvent.click(page.getByRole('radio', { name: 'Label + value' }));

      await expect.element(preview().getByText('Description')).toBeVisible();
      await expect.element(preview().getByText('notes')).toHaveProperty('tagName', 'STRONG');
    });

    it('takes the place of an empty line', async () => {
      await openWorkPackageAttributeDialog();
      await pickWorkPackage('Redesign', 'Redesign onboarding flow');
      await pickAttribute('Description');
      await userEvent.click(insertButton());

      await expect.element(dialog()).not.toBeInTheDocument();
      expect(blocks()[0]).toEqual({
        type: 'openProjectWorkPackageAttributeBlock',
        props: { wpid: '321', displayId: 'PROJ-321', attribute: 'description', display: 'value' },
      });
      await expect.element(page.getByText('Kick-off')).toBeVisible();
    });

    it('follows a line that holds more', async () => {
      await openEditorAndType('Before /attribute');
      await userEvent.click(page.getByText('Work package attribute').first());
      await pickWorkPackage('Redesign', 'Redesign onboarding flow');
      await pickAttribute('Description');
      await userEvent.click(insertButton());

      await expect.element(dialog()).not.toBeInTheDocument();
      expect(editor.document[0].content).toEqual([{ type: 'text', text: 'Before ', styles: {} }]);
      expect(blocks()[1].type).toBe('openProjectWorkPackageAttributeBlock');
    });

    function selectionMarks() {
      const frame = document.querySelector('.op-bn-wp-attribute-block')!;
      const marked = Array.from(document.querySelectorAll('.ProseMirror-selectednode'))
        .filter((node) => node.contains(frame))
        .map((node) => getComputedStyle(node))
        .filter((style) => style.outlineStyle !== 'none' || style.backgroundColor !== 'rgba(0, 0, 0, 0)');
      return { ring: getComputedStyle(frame).boxShadow !== 'none', other: marked.length };
    }

    it('marks itself once when selected with the keys or the pointer', async () => {
      await openWorkPackageAttributeDialog();
      await pickWorkPackage('Redesign', 'Redesign onboarding flow');
      await pickAttribute('Description');
      await userEvent.click(insertButton());
      await expect.element(page.getByText('Kick-off')).toBeVisible();

      editor.insertBlocks([{ type: 'paragraph', content: 'Above' }], editor.document[0], 'before');
      await userEvent.click(page.getByText('Above'));
      await userEvent.keyboard('{End}{ArrowDown}');
      await vi.waitFor(() => expect(selectionMarks()).toEqual({ ring: true, other: 0 }));

      await userEvent.click(page.getByText('Kick-off'));
      await expect.element(page.getByTestId('attribute-display-menu')).toBeVisible();
      expect(selectionMarks()).toEqual({ ring: true, other: 0 });
    });

    it('selects no text when clicked', async () => {
      await openWorkPackageAttributeDialog();
      await pickWorkPackage('Redesign', 'Redesign onboarding flow');
      await pickAttribute('Description');
      await userEvent.click(insertButton());

      await userEvent.click(page.getByText('Kick-off'));

      await expect.element(page.getByTestId('attribute-display-menu')).toBeVisible();
      const selected = document.getSelection()?.toString() ?? '';
      expect(selected).not.toContain('Kick-off');
      expect(getComputedStyle(page.getByText('Kick-off').element()).userSelect).toBe('none');
    });

    it('keeps the blocks nested in an empty line', async () => {
      editor.insertBlocks(
        [{ type: 'paragraph', content: [], children: [{ type: 'paragraph', content: 'Nested' }] }],
        editor.document[0],
        'before',
      );
      await expect.element(page.getByText('Nested')).toBeVisible();
      const parent = page.getByText('Nested').element().closest('[data-node-type="blockOuter"]')!
        .parentElement!.closest('[data-node-type="blockOuter"]')!.querySelector('[data-content-type="paragraph"]')!;
      await userEvent.click(parent);
      await userEvent.keyboard('/attribute');
      await userEvent.click(page.getByText('Work package attribute').first());
      await pickWorkPackage('Redesign', 'Redesign onboarding flow');
      await pickAttribute('Description');
      await userEvent.click(insertButton());

      await expect.element(page.getByText('Kick-off')).toBeVisible();
      await expect.element(page.getByText('Nested')).toBeVisible();
    });

    it('switches what it shows from its menu', async () => {
      await openWorkPackageAttributeDialog();
      await pickWorkPackage('Redesign', 'Redesign onboarding flow');
      await pickAttribute('Description');
      await userEvent.click(insertButton());

      await userEvent.click(page.getByText('Kick-off'));
      await userEvent.click(page.getByRole('menuitemradio', { name: 'Label + value' }));

      await expect.element(page.getByText('Description', { exact: true })).toBeVisible();
      expect(blocks()[0].props).toMatchObject({ display: 'both' });
    });
  });

  describe('in an editor without the long text block', () => {
    it('offers no long text attributes', async () => {
      await cleanup();
      renderEditor({
        schema: BlockNoteSchema.create().extend({
          inlineContentSpecs: { openProjectWorkPackageAttribute: openProjectWorkPackageAttributeSpec },
        }),
      });
      await openWorkPackageAttributeDialog();
      await pickWorkPackage('Redesign', 'Redesign onboarding flow');
      await userEvent.click(page.getByRole('combobox', { name: 'Attribute' }));

      await expect.element(page.getByRole('option', { name: 'Status' })).toBeVisible();
      expect(page.getByRole('option', { name: 'Description' }).elements()).toHaveLength(0);
    });
  });
});
