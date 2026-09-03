import { expect } from 'vitest';
import { delay, http } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { worker } from '../mocks/browser';

export function holdBackFormLoads(ms:number) {
  worker.use(http.post('http://localhost:3000/api/v3/work_packages/form', async () => { await delay(ms); }));
}

export function colorChannelsOf(element:Element):string[] {
  const styles = getComputedStyle(element);
  return ['--color-r', '--color-g', '--color-b'].map((channel) => styles.getPropertyValue(channel).trim());
}

export const modalPanel = ():HTMLElement => page.getByTestId('create-wp-modal').element() as HTMLElement;

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

export async function selectOptionNamed(label:string, option:string) {
  await userEvent.click(page.getByLabelText(label));
  await expect.element(page.getByRole('option', { name: option })).toBeVisible();
  await userEvent.click(page.getByRole('option', { name: option }));
}

// The list closes on every pick, so it is opened again for the next value.
export async function pickValues(label:string, ...options:string[]) {
  for (const option of options) {
    await userEvent.click(page.getByLabelText(label));
    await expect.element(page.getByRole('option', { name: option })).toBeVisible();
    await userEvent.click(page.getByRole('option', { name: option }));
  }
}

export async function fillRequiredFields(subject:string) {
  await userEvent.fill(page.getByLabelText('Subject *'), subject);
  await fillRequiredFieldsBesidesSubject();
}

export async function fillRequiredFieldsBesidesSubject() {
  await pickProject();

  await expect.element(page.getByLabelText('Type *')).toBeVisible();
  await selectOptionNamed('Type *', 'Task');

  await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();
  await userEvent.click(page.getByLabelText('Supervisor *'));
  await expect.element(page.getByRole('option', { name: 'Anna Kovalenko' })).toBeVisible();
  await userEvent.click(page.getByRole('option', { name: 'Anna Kovalenko' }));

  await selectOptionNamed('Department *', 'Design');

  await pickValues('Labels *', 'Accessibility');
}
