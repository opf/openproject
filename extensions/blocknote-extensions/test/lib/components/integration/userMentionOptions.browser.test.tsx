import { describe, expect, it, vi } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import type { Locator } from 'vitest/browser';
import { renderEditorWithHandle } from '../../../helpers/renderEditor';
import { mentionContent, paragraphWith } from '../../../helpers/content';
import { blockTextWithNodes, selectedNodeType } from '../../../helpers/headlessEditor';
import { tapElement, withNavigationPrevented } from '../../../helpers/editorHelpers';
import { USER_MENTION_TYPE } from '../../../../lib/utils/nodeTypes';

const anna = { userId: '7', name: 'Anna Kovalenko' };
const peter = { userId: '8', name: 'Peter Lang' };
const OPEN_LABEL = "Open Anna Kovalenko's profile in new tab";

const popover = () => page.getByTestId('popover-content');

async function renderMention({ person = anna, textAfter = ' for the review' } = {}) {
  const editor = await renderEditorWithHandle({
    initialContent: [
      paragraphWith('Thanks ', mentionContent(person.userId, person.name), ...(textAfter ? [textAfter] : [])),
      paragraphWith('Somewhere else'),
    ],
  });
  const link = page.getByRole('link', { name: person.name });
  await expect.element(link).toBeVisible();
  const pill = page.getByRole('button', { name: `User ${person.name}` });
  return { editor, link, pill, avatar: pill.getByTestId('avatar') };
}

async function openOptions(avatar:Locator) {
  await userEvent.click(avatar);
  await expect.element(popover()).toBeVisible();
}

describe('User mention options', () => {
  it('selects the mention and shows Open and Remove when the pill is clicked', async () => {
    const { editor, avatar } = await renderMention();
    await expect.element(avatar.element().querySelector('img')!).toBeVisible();

    await openOptions(avatar);

    await expect.element(page.getByRole('button', { name: OPEN_LABEL })).toBeVisible();
    await expect.element(page.getByTestId('remove-btn')).toBeVisible();
    expect(selectedNodeType(editor)).toBe(USER_MENTION_TYPE);
  });

  it('opens the popover from the initials of a user without a picture', async () => {
    const { avatar } = await renderMention({ person: peter });
    await expect.element(avatar).toHaveTextContent('PL');

    await openOptions(avatar);
  });

  it('closes the popover when the pill is clicked again', async () => {
    const { avatar } = await renderMention();
    await openOptions(avatar);

    await userEvent.click(avatar);

    await expect.element(popover()).not.toBeInTheDocument();
  });

  it('removes the selected mention with Backspace', async () => {
    const { editor, avatar } = await renderMention();
    await openOptions(avatar);

    await userEvent.keyboard('{Backspace}');

    await expect.poll(() => blockTextWithNodes(editor)).toBe('Thanks  for the review');
  });

  it('removes the selected mention with Delete', async () => {
    const { editor, avatar } = await renderMention();
    await openOptions(avatar);

    await userEvent.keyboard('{Delete}');

    await expect.poll(() => blockTextWithNodes(editor)).toBe('Thanks  for the review');
  });

  it('removes the mention with Backspace from the caret right after it', async () => {
    const { editor } = await renderMention({ textAfter: '' });
    editor.focus();
    editor.setTextCursorPosition(editor.document[0], 'end');
    expect(selectedNodeType(editor)).toBeUndefined();

    await userEvent.keyboard('{Backspace}');

    await expect.poll(() => blockTextWithNodes(editor)).toBe('Thanks ');
  });

  it('removes the mention and closes the popover from the Remove button', async () => {
    const { editor, avatar } = await renderMention();
    await openOptions(avatar);

    await userEvent.click(page.getByTestId('remove-btn'));

    await expect.poll(() => blockTextWithNodes(editor)).toBe('Thanks  for the review');
    await expect.element(popover()).not.toBeInTheDocument();
  });

  it('opens the profile in a new tab from the Open button', async () => {
    const openSpy = vi.spyOn(window, 'open').mockReturnValue(null);
    try {
      const { avatar } = await renderMention();
      await openOptions(avatar);

      await userEvent.click(page.getByRole('button', { name: OPEN_LABEL }));

      expect(openSpy).toHaveBeenCalledWith('http://localhost:3000/users/7', '_blank', 'noopener,noreferrer');
    } finally {
      openSpy.mockRestore();
    }
  });

  it('closes the popover on a click outside the pill', async () => {
    const { avatar } = await renderMention();
    await openOptions(avatar);

    await userEvent.click(page.getByText('Somewhere else'));

    await expect.element(popover()).not.toBeInTheDocument();
  });

  it('does not open the popover when the name link is clicked', async () => {
    const { link } = await renderMention();

    const clicks = await withNavigationPrevented(() => userEvent.click(link));

    expect(clicks).toEqual([{ defaultPrevented: false, href: 'http://localhost:3000/users/7' }]);
    await expect.element(popover()).not.toBeInTheDocument();
  });

  it('opens the popover from one tap on the pill, but not from a tap on the name', async () => {
    const { link, avatar } = await renderMention();

    const nameTap = tapElement(link.element());
    expect(nameTap.defaultPrevented).toBe(false);
    await expect.element(popover()).not.toBeInTheDocument();

    tapElement(avatar.element());
    await expect.element(popover()).toBeVisible();
  });
});
