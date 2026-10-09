import { describe, expect, it } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import type { Locator } from 'vitest/browser';
import { renderEditorInShadowDom } from '../../../helpers/renderEditor';
import { chipContent, mentionContent, paragraphWith } from '../../../helpers/content';

// Inside a shadow root a document listener sees every press retargeted to the
// host, so these guard that a press on the node itself is not taken as outside.

const popover = () => page.getByTestId('popover-content');

describe('User mention options inside a shadow root', () => {
  async function renderMention() {
    await renderEditorInShadowDom({
      initialContent: [
        paragraphWith('Thanks ', mentionContent('7', 'Anna Kovalenko'), ' for the review'),
        paragraphWith('Somewhere else'),
      ],
    });
    const pill = page.getByRole('button', { name: 'User Anna Kovalenko' });
    await expect.element(pill).toBeVisible();
    return { pill, avatar: pill.getByTestId('avatar') };
  }

  async function openOptions(avatar:Locator) {
    await userEvent.click(avatar);
    await expect.element(popover()).toBeVisible();
  }

  it('opens the popover when the pill is clicked', async () => {
    const { avatar } = await renderMention();

    await openOptions(avatar);

    await expect.element(page.getByTestId('remove-btn')).toBeVisible();
  });

  it('closes the popover when the pill is clicked again', async () => {
    const { avatar } = await renderMention();
    await openOptions(avatar);

    await userEvent.click(avatar);

    await expect.element(popover()).not.toBeInTheDocument();
  });

  it('removes the mention from the Remove button', async () => {
    const { pill, avatar } = await renderMention();
    await openOptions(avatar);

    await userEvent.click(page.getByTestId('remove-btn'));

    await expect.element(pill).not.toBeInTheDocument();
    await expect.element(popover()).not.toBeInTheDocument();
  });

  it('closes the popover on a click outside the pill', async () => {
    const { avatar } = await renderMention();
    await openOptions(avatar);

    await userEvent.click(page.getByText('Somewhere else'));

    await expect.element(popover()).not.toBeInTheDocument();
  });
});

describe('Inline work package options inside a shadow root', () => {
  it('closes the popover when the chip is clicked again', async () => {
    await renderEditorInShadowDom({ initialContent: [paragraphWith('See ', chipContent('123'))] });
    const chip = page.getByText('#123', { exact: true });
    await expect.element(chip).toBeVisible();

    await userEvent.click(chip);
    await expect.element(popover()).toBeVisible();

    await userEvent.click(chip);

    await expect.element(popover()).not.toBeInTheDocument();
  });
});
