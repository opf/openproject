import { describe, it, expect } from 'vitest';
import { render } from 'vitest-browser-react';
import { page } from 'vitest/browser';
import '@blocknote/core/fonts/inter.css';
import { WpChipXS, WpChipS } from '../../../../lib/components/InlineWorkPackage/InlineChips';
import { mockWorkPackage } from '../../../mocks/handlers';

const descenderSubject = 'Buggy typography jjggyypp';

const mockWpWithDescenders = { ...mockWorkPackage, subject: descenderSubject };

const chipParts = () => {
  const chipBox = document.querySelector('.op-bn-inline-wp-base');
  if (!chipBox) throw new Error('chip did not render');

  const box = chipBox.getBoundingClientRect();
  const boxFontSize = parseFloat(getComputedStyle(chipBox).fontSize);

  return [...chipBox.children].map((part) => {
    const partBox = part.getBoundingClientRect();
    return {
      text: part.textContent,
      below: partBox.bottom - box.bottom,
      above: box.top - partBox.top,
      isLargerThanBox: parseFloat(getComputedStyle(part).fontSize) > boxFontSize,
    };
  });
};

describe('InlineChips - the chip box contains its parts', () => {
  it.each([
    ['WpChipS', <WpChipS wp={mockWpWithDescenders} />],
    ['WpChipXS', <WpChipXS wp={mockWpWithDescenders} />],
  ])('%s keeps every part inside the painted chip box', async (_name, chip) => {
    render(<div style={{ width: '600px', fontFamily: 'Inter' }}>{chip}</div>);

    await expect.element(page.getByText(descenderSubject)).toBeVisible();
    await document.fonts.load('400 12px Inter');
    await document.fonts.load('600 14px Inter');
    expect(document.fonts.check('600 14px Inter')).toBe(true);

    const parts = chipParts();
    expect(parts.length).toBeGreaterThan(1);

    for (const part of parts) {
      expect.soft(
        part.below,
        `"${part.text}" hangs ${part.below.toFixed(2)}px below the chip box`,
      ).toBeLessThanOrEqual(0);

      if (part.isLargerThanBox) continue;

      expect.soft(
        part.above,
        `"${part.text}" sticks ${part.above.toFixed(2)}px above the chip box`,
      ).toBeLessThanOrEqual(0);
    }
  });
});
