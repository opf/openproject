import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditorInShadowDom } from '../../../helpers/renderEditor';

const card = (wpid:number) => ({ type: 'openProjectWorkPackageBlock', props: { wpid } });

async function renderCardsBetweenParagraphs() {
  const { shadowRoot } = await renderEditorInShadowDom({
    initialContent: [
      { type: 'paragraph', content: 'above' },
      card(123),
      card(456),
      { type: 'paragraph', content: 'below' },
    ],
  });
  await expect.poll(() => shadowRoot.querySelectorAll('[data-testid="block-card"]').length).toBe(2);

  await userEvent.click(page.getByText('above'));
  await userEvent.keyboard('{End}');

  return shadowRoot;
}

describe('selection styles inside a shadow root', () => {
  it('hides the text caret while a work package card is selected', async () => {
    const shadowRoot = await renderCardsBetweenParagraphs();

    await userEvent.keyboard('{ArrowDown}');
    await expect.poll(() => shadowRoot.querySelector('.ProseMirror-hideselection')).not.toBeNull();

    const paragraphBelow = page.getByText('below').element();
    expect(getComputedStyle(paragraphBelow).caretColor).toBe('rgba(0, 0, 0, 0)');
  });

  it('shows the gap cursor between two work package cards', async () => {
    const shadowRoot = await renderCardsBetweenParagraphs();

    await userEvent.keyboard('{ArrowDown}{ArrowDown}');
    await expect.poll(() => shadowRoot.querySelector('.ProseMirror-gapcursor')).not.toBeNull();

    const gapCursorLine = getComputedStyle(shadowRoot.querySelector('.ProseMirror-gapcursor')!, '::after');
    expect(gapCursorLine.borderTopStyle).toBe('solid');
  });
});
