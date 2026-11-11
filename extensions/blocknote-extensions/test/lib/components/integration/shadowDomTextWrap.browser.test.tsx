import { describe, it, expect } from 'vitest';
import { page } from 'vitest/browser';
import { renderEditorInShadowDom } from '../../../helpers/renderEditor';

const unbreakableWord = 'q'.repeat(300);

const proseMirrorWrapRules = (shadowRoot:ShadowRoot) => Array.from(shadowRoot.styleSheets)
  .flatMap((styleSheet) => Array.from(styleSheet.cssRules))
  .filter((rule):rule is CSSStyleRule => rule instanceof CSSStyleRule)
  .filter((rule) => rule.selectorText === '.ProseMirror');

describe('paragraph text wrapping inside a shadow root', () => {
  it('wraps an unbreakable word instead of growing the paragraph past the editor', async () => {
    let editor:any;
    const { shadowRoot } = await renderEditorInShadowDom({ onEditor: (createdEditor) => { editor = createdEditor; } });

    const editorLocator = page.getByRole('textbox');
    await expect.element(editorLocator).toBeVisible();

    editor.replaceBlocks(editor.document, [{ type: 'paragraph', content: unbreakableWord }]);
    await expect.element(page.getByText(unbreakableWord)).toBeVisible();

    const paragraph = shadowRoot.querySelector('.bn-inline-content')!;

    expect(paragraph.scrollWidth).toBeLessThanOrEqual(paragraph.clientWidth);
  });

  it('puts the ProseMirror wrap rule into the shadow root', async () => {
    const { shadowRoot } = await renderEditorInShadowDom();

    await expect.element(page.getByRole('textbox')).toBeVisible();

    expect(proseMirrorWrapRules(shadowRoot).some((rule) => rule.style.overflowWrap === 'break-word')).toBe(true);
  });
});
