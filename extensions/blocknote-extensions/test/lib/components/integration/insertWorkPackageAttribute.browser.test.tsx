import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { renderEditor } from '../../../helpers/renderEditor';
import { openWorkPackageAttributeDialog, SEARCH_PLACEHOLDER } from '../../../helpers/editorHelpers';
import { worker } from '../../../mocks/browser';
import { mockAttributeWorkPackage, mockMilestoneWorkPackage } from '../../../mocks/workPackageAttributes';

interface InlineNode { type:string, props?:Record<string, unknown> }

let editor:{ document:{ content?:InlineNode[] }[] };

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
  it('offers attributes only once a work package is chosen', async () => {
    await openWorkPackageAttributeDialog();

    await expect.element(page.getByPlaceholder('Select a work package first')).toBeDisabled();
    const attributeStyle = getComputedStyle(page.getByPlaceholder('Select a work package first').element());
    expect(attributeStyle.cursor).toBe('not-allowed');
    expect(attributeStyle.backgroundColor).not.toBe(getComputedStyle(workPackageField().element()).backgroundColor);
    await expect.element(preview()).toHaveTextContent('Choose a work package and an attribute');
    await expect.element(insertButton()).toBeDisabled();
  });

  it('draws its preview with the colors of the editor it was opened from', async () => {
    await openWorkPackageAttributeDialog();
    const editorStyle = getComputedStyle(document.querySelector('.bn-container')!);
    const dialogStyle = getComputedStyle(dialog().element());

    for (const name of ['--bn-colors-highlights-blue-text', '--bn-colors-editor-text']) {
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

    await expect.element(workPackageField()).toHaveValue(`PROJ-321 ${subject}`);
    const box = preview().element();
    expect(box.scrollWidth).toBeLessThanOrEqual(box.clientWidth);
  });

  it('inserts the chosen attribute with what it should show', async () => {
    await openWorkPackageAttributeDialog();
    await pickWorkPackage('Redesign', 'Redesign onboarding flow');
    await pickAttribute('Status');

    await expect.element(preview()).toHaveTextContent('In progress');
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
    expect(attributeProps()).toEqual([]);
  });

  it('closes on Escape', async () => {
    await openWorkPackageAttributeDialog();
    await userEvent.keyboard('{Escape}');

    await expect.element(dialog()).not.toBeInTheDocument();
    expect(attributeProps()).toEqual([]);
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
    await userEvent.click(page.getByRole('menuitemradio', { name: 'Label', exact: true }));

    await expect.element(page.getByRole('button', { name: 'Status', exact: true })).toBeVisible();
    await expect.element(page.getByTestId('attribute-display-menu')).not.toBeInTheDocument();
    expect(attributeProps()[0]).toMatchObject({ display: 'label' });
  });

  it('keeps the picked work package until another one is picked', async () => {
    await openWorkPackageAttributeDialog();
    await pickWorkPackage('Redesign', 'Redesign onboarding flow');
    await expect.element(workPackageField()).toHaveValue('PROJ-321 Redesign onboarding flow');

    await userEvent.fill(workPackageField(), 'beta');
    await expect.element(page.getByRole('option', { name: /Public beta/ })).toBeVisible();
    await userEvent.keyboard('{Escape}');

    await expect.element(workPackageField()).toHaveValue('PROJ-321 Redesign onboarding flow');
    await expect.element(dialog()).toBeVisible();

    await userEvent.fill(workPackageField(), 'beta');
    await userEvent.click(page.getByRole('radio', { name: 'Label', exact: true }));
    await expect.element(workPackageField()).toHaveValue('PROJ-321 Redesign onboarding flow');
  });

  it('prefills the next invocation with the previous choice', async () => {
    await openWorkPackageAttributeDialog();
    await pickWorkPackage('Redesign', 'Redesign onboarding flow');
    await pickAttribute('Status');
    await userEvent.click(page.getByRole('radio', { name: 'Label + value' }));
    await userEvent.click(insertButton());
    await expect.element(dialog()).not.toBeInTheDocument();

    await userEvent.keyboard('{End}');
    await openWorkPackageAttributeDialog();

    await expect.element(workPackageField()).toHaveValue('PROJ-321 Redesign onboarding flow');
    await expect.element(preview()).toHaveTextContent('Status: In progress');
    await expect.element(page.getByRole('radio', { name: 'Label + value' })).toHaveAttribute('aria-checked', 'true');
  });
});
