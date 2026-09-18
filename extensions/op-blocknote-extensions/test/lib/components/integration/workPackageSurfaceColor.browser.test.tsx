import { describe, it, expect, afterEach } from 'vitest';
import { page } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertInlineWorkPackageViaSlashMenu,
  convertToCompactCard,
} from '../../../helpers/editorHelpers';

const PRIMER_MUTED_LIGHT = 'rgb(246, 248, 250)';
const BLOCKNOTE_DARK = 'rgb(63, 63, 63)';

function surfaceOf(selector:string) {
  return getComputedStyle(document.querySelector(selector)!).backgroundColor;
}

function switchToDarkScheme() {
  page.getByRole('textbox').element().closest('[data-color-scheme]')!
    .setAttribute('data-color-scheme', 'dark');
}

describe('Work package surface colour', () => {
  afterEach(() => {
    document.documentElement.style.removeProperty('--bgColor-muted');
  });

  it('paints the block card on the Primer muted surface', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    expect(surfaceOf('[data-testid="block-wp-wrapper"]')).toBe(PRIMER_MUTED_LIGHT);
  });

  it('paints the inline chip on the same surface as the block card', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    expect(surfaceOf('.op-bn-inline-wp-base')).toBe(PRIMER_MUTED_LIGHT);
  });

  it('follows the host application when it defines --bgColor-muted', async () => {
    document.documentElement.style.setProperty('--bgColor-muted', 'rgb(1, 2, 3)');
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    expect(surfaceOf('[data-testid="block-wp-wrapper"]')).toBe('rgb(1, 2, 3)');
  });

  it('leaves the dark mode surface untouched', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();
    switchToDarkScheme();

    expect(surfaceOf('[data-testid="block-wp-wrapper"]')).toBe(BLOCKNOTE_DARK);
  });
});
