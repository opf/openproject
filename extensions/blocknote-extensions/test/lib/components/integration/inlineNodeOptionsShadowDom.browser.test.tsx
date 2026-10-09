import { describe, expect, it } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditorInShadowDom } from '../../../helpers/renderEditor';
import { chipContent, paragraphWith } from '../../../helpers/content';

// Inside a shadow root a document listener sees every press retargeted to the
// host, so these guard that a press on the node itself is not taken as outside.

const popover = () => page.getByTestId('popover-content');

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
