// @vitest-environment jsdom
import { describe, it, expect, beforeAll, afterAll, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { ServerStyleSheet } from 'styled-components';
import { InlineChip } from '../../../../lib/components/InlineWorkPackage/chipLayouts';

describe('Inline chip styles', () => {
  beforeAll(() => vi.stubGlobal('matchMedia', () => ({ matches: false })));
  afterAll(() => vi.unstubAllGlobals());

  // Asserted on the emitted stylesheet, not in the browser: Chromium aliases the prefixed
  // and unprefixed properties in both getComputedStyle and the CSSOM, so only the shipped
  // CSS shows whether Safari gets a declaration it understands.
  it('suppresses text selection with the prefixed properties Safari needs', () => {
    const sheet = new ServerStyleSheet();
    renderToStaticMarkup(sheet.collectStyles(<InlineChip />));
    const css = sheet.getStyleTags();

    expect(css).toContain('-webkit-user-select:none');
    expect(css).toContain('-webkit-touch-callout:none');
  });
});
