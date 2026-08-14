import { expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';

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

export async function pickProject(name = 'Demo project') {
  await userEvent.click(page.getByLabelText('Project *'));
  await expect.element(page.getByRole('option', { name })).toBeVisible();
  await userEvent.click(page.getByRole('option', { name }));
}

// Chosen by what the option reads as; a plain string would be matched against
// its value, which here is an API href. Looked up inside the field, so an
// option of the same name elsewhere on the form is not what gets picked.
export async function selectOptionNamed(label:string, option:string) {
  const select = page.getByLabelText(label).element() as HTMLSelectElement;
  const choices = Array.from(select.options);
  const target = choices.find((choice) => choice.text === option);
  if (!target) throw new Error(`No option "${option}" in "${label}", only: ${choices.map((choice) => choice.text).join(', ')}`);

  await userEvent.selectOptions(page.getByLabelText(label), target);
}

export async function fillRequiredFields(subject:string) {
  await userEvent.fill(page.getByLabelText('Subject *'), subject);
  await pickProject();

  await expect.element(page.getByLabelText('Type *')).toBeVisible();
  await selectOptionNamed('Type *', 'Task');

  await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();
  await userEvent.click(page.getByLabelText('Supervisor *'));
  await expect.element(page.getByRole('option', { name: 'Anna Kovalenko' })).toBeVisible();
  await userEvent.click(page.getByRole('option', { name: 'Anna Kovalenko' }));

  await selectOptionNamed('Department *', 'Design');
}
