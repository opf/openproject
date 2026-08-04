import { expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';

export async function openCreateModal(before = '') {
  const editorEl = page.getByRole('textbox');
  await userEvent.click(editorEl);
  if (before) await userEvent.type(editorEl, before);
  await userEvent.type(editorEl, '/');

  await expect.element(page.getByText('Create new work package').first()).toBeVisible();
  await userEvent.click(page.getByText('Create new work package').first());
  await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
}

export async function pickProject(name = 'Demo project') {
  await userEvent.click(page.getByLabelText('Project *'));
  await expect.element(page.getByRole('option', { name })).toBeVisible();
  await userEvent.click(page.getByRole('option', { name }));
}

export async function fillRequiredFields(subject:string) {
  await userEvent.fill(page.getByLabelText('Subject *'), subject);
  await pickProject();

  await expect.element(page.getByLabelText('Type *')).toBeVisible();
  await userEvent.selectOptions(page.getByLabelText('Type *'), '/api/v3/types/1');

  await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();
  await userEvent.click(page.getByLabelText('Supervisor *'));
  await expect.element(page.getByRole('option', { name: 'Anna Kovalenko' })).toBeVisible();
  await userEvent.click(page.getByRole('option', { name: 'Anna Kovalenko' }));

  await userEvent.selectOptions(page.getByLabelText('Department *'), '/api/v3/custom_options/7');
}
