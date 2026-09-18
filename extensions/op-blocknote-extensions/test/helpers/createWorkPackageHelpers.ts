import { expect, onTestFinished } from 'vitest';
import { delay, http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { worker } from '../mocks/browser';
import { createFormFor } from '../mocks/handlers';
import type { FormRequestBody } from '../mocks/handlers';

const PHONE = { width: 390, height: 640 };
const DESKTOP = { width: 800, height: 600 };

export function holdBackFormLoads(ms:number) {
  worker.use(http.post('http://localhost:3000/api/v3/work_packages/form', async () => { await delay(ms); }));
}

export function withGeneratedSubjectFor(typeHref:string) {
  worker.use(http.post('http://localhost:3000/api/v3/work_packages/form', async ({ request }) => {
    const body = await request.json() as FormRequestBody;
    const form = createFormFor(body);
    const schema = form._embedded.schema as Record<string, Record<string, unknown>>;

    if (body._links?.type?.href === typeHref) {
      schema.subject = {
        ...schema.subject,
        hasDefault: true,
        placeholder: 'Automatically generated through type',
      };
    }

    return HttpResponse.json(form);
  }));
}

export function colorChannelsOf(element:Element):string[] {
  const styles = getComputedStyle(element);
  return ['--color-r', '--color-g', '--color-b'].map((channel) => styles.getPropertyValue(channel).trim());
}

export async function onAPhone(height = PHONE.height) {
  await page.viewport(PHONE.width, height);
  onTestFinished(() => page.viewport(DESKTOP.width, DESKTOP.height));
}

export const modalPanel = ():HTMLElement => page.getByTestId('create-wp-modal').element() as HTMLElement;

export const pickerList = (label:string):HTMLElement =>
  page.getByRole('listbox', { name: label }).element().closest<HTMLElement>('[data-testid$="-popover"]')!;

export function gapToField(label:string, field:Element):number {
  const list = pickerList(label).getBoundingClientRect();
  const box = field.getBoundingClientRect();
  return Math.round(Math.min(Math.abs(list.top - box.bottom), Math.abs(box.top - list.bottom)));
}

export const modalBody = ():HTMLElement => modalPanel().querySelector<HTMLElement>('form > div')!;

export async function chooseCreateCommand() {
  await expect.element(page.getByText('Create new work package').first()).toBeVisible();
  await userEvent.click(page.getByText('Create new work package').first());
  await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
}

export async function openCreateModal(before = '') {
  const editorEl = page.getByRole('textbox');
  await userEvent.click(editorEl);
  if (before) await userEvent.type(editorEl, before);
  await userEvent.type(editorEl, '/');

  await chooseCreateCommand();
}

// Where the last creation left the cursor, so a second work package can follow
// without clicking into a document that already holds a card.
export async function openCreateModalAtCursor() {
  await userEvent.keyboard('/');
  await chooseCreateCommand();
}

export async function openCreateModalFromToolbar() {
  const button = page.getByRole('button', { name: 'Create work package' });
  await expect.element(button).toBeVisible();
  await userEvent.click(button);
  await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
}

export async function pickProject(name = 'Demo project') {
  await userEvent.click(page.getByLabelText('Project *'));
  await expect.element(page.getByRole('treeitem', { name })).toBeVisible();
  await userEvent.click(page.getByRole('treeitem', { name }));
}

export async function clearProject() {
  await userEvent.click(page.getByLabelText('Project *'));
  await userEvent.click(page.getByTestId('op-bn-create-wp-project-list-deselect'));
}

export async function openPicker(label:string, option:string) {
  await userEvent.click(page.getByLabelText(label));
  await expect.element(page.getByRole('option', { name: option })).toBeVisible();
}

export async function selectOptionNamed(label:string, option:string) {
  await openPicker(label, option);
  await userEvent.click(page.getByRole('option', { name: option }));
}

// The list closes on every pick, so it is opened again for the next value.
export async function pickValues(label:string, ...options:string[]) {
  for (const option of options) await selectOptionNamed(label, option);
}

export async function fillRequiredFields(subject:string) {
  await userEvent.fill(page.getByLabelText('Subject *'), subject);
  await fillRequiredFieldsBesidesSubject();
}

export async function fillRequiredFieldsBesidesSubject(type = 'Task') {
  await pickProject();

  await expect.element(page.getByLabelText('Type *')).toBeVisible();
  await selectOptionNamed('Type *', type);

  await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();
  await selectOptionNamed('Supervisor *', 'Anna Kovalenko');

  await selectOptionNamed('Department *', 'Design');

  await pickValues('Labels *', 'Accessibility');
}

