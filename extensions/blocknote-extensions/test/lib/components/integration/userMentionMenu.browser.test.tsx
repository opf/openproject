import { afterEach, describe, expect, it } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { worker } from '../../../mocks/browser';
import { renderEditor, renderEditorWithHandle } from '../../../helpers/renderEditor';
import { openEditorAndType } from '../../../helpers/editorHelpers';
import { mentionContent, textContent } from '../../../helpers/content';
import { blockContent } from '../../../helpers/headlessEditor';

const mentionMenu = () => page.getByTestId('mention-menu');

describe('@ mention menu', () => {
  afterEach(() => worker.resetHandlers());

  it('lists people as soon as @ is typed', async () => {
    renderEditor();
    await openEditorAndType('Hi @');

    await expect.element(mentionMenu().getByText('Anna Kovalenko')).toBeVisible();
    await expect.element(mentionMenu().getByText('Peter Lang')).toBeVisible();
  });

  it('replaces the query with the picked person followed by a space', async () => {
    const editor = await renderEditorWithHandle();
    await openEditorAndType('Hi @pet');
    await userEvent.click(mentionMenu().getByText('Peter Lang'));
    await userEvent.keyboard('there');

    await expect.poll(() => blockContent(editor)).toEqual([
      textContent('Hi '),
      mentionContent('8', 'Peter Lang'),
      textContent(' there'),
    ]);
  });

  it('picks with the keyboard', async () => {
    renderEditor();
    await openEditorAndType('@');
    await expect.element(mentionMenu().getByText('Peter Lang')).toBeVisible();
    await userEvent.keyboard('{ArrowDown}{Enter}');

    await expect.element(page.getByRole('textbox').getByRole('link', { name: 'Peter Lang' })).toBeVisible();
  });

  it('keeps the typed text when Enter is pressed and nobody matches', async () => {
    renderEditor();
    await openEditorAndType('@zzz');
    await expect.element(mentionMenu()).toHaveTextContent('No results');
    await userEvent.keyboard('{Enter}');

    await expect.element(page.getByRole('textbox')).toMatchTextContent(/^@zzz$/);
    await expect.element(mentionMenu()).not.toBeInTheDocument();
  });

  it('closes on Escape and keeps the typed query', async () => {
    renderEditor();
    await openEditorAndType('@pet');
    await expect.element(mentionMenu().getByText('Peter Lang')).toBeVisible();

    await userEvent.keyboard('{Escape}');

    await expect.element(mentionMenu()).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toMatchTextContent(/^@pet$/);
  });

  it('does not open inside an email address', async () => {
    renderEditor();
    await openEditorAndType('ihor@op');
    await expect.element(page.getByRole('textbox')).toMatchTextContent(/^ihor@op$/);
    await expect.element(mentionMenu()).not.toBeInTheDocument();

    await userEvent.keyboard(' @');
    await expect.element(mentionMenu()).toBeVisible();
  });

  it('says so when the search fails', async () => {
    worker.use(http.get('http://localhost:3000/api/v3/principals', () => new HttpResponse(null, { status: 500 })));
    renderEditor();
    await openEditorAndType('@a');

    await expect.element(mentionMenu()).toHaveTextContent('Error. Unable to load content.');
  });
});
