import { describe, it, expect } from 'vitest';
import { render } from 'vitest-browser-react';
import { page } from 'vitest/browser';
import { WpChipXS, WpChipS } from '../../../../lib/components/InlineWorkPackage/InlineChips';
import { mockWorkPackage } from '../../../mocks/handlers';

const longSubject = 'This is a very long work package subject that must always be shown in full without any truncation';

const mockWpWithLongSubject = {
  ...mockWorkPackage,
  subject: longSubject,
};

describe('InlineChips - long subject', () => {
  it('WpChipXS shows the full subject and wraps instead of overflowing a narrow container', async () => {
    render(
      <div data-testid="narrow-wrapper" style={{ width: '300px' }}>
        <WpChipXS wp={mockWpWithLongSubject} />
      </div>
    );

    const wrapperLocator = page.getByTestId('narrow-wrapper');
    await expect.element(wrapperLocator).toBeVisible();
    await expect.element(page.getByText(longSubject)).toBeVisible();

    const wrapperElement = await wrapperLocator.element();
    // scrollWidth > clientWidth means content overflows horizontally (chip extends past the
    // right edge of the editor). Wrapping keeps scrollWidth === clientWidth.
    expect(wrapperElement.scrollWidth).toBeLessThanOrEqual(wrapperElement.clientWidth);
  });

  it('WpChipS shows the full subject and wraps instead of overflowing a narrow container', async () => {
    render(
      <div data-testid="narrow-wrapper" style={{ width: '300px' }}>
        <WpChipS wp={mockWpWithLongSubject} />
      </div>
    );

    const wrapperLocator = page.getByTestId('narrow-wrapper');
    await expect.element(wrapperLocator).toBeVisible();
    await expect.element(page.getByText(longSubject)).toBeVisible();

    const wrapperElement = await wrapperLocator.element();
    // scrollWidth > clientWidth means content overflows horizontally (chip extends past the
    // right edge of the editor). Wrapping keeps scrollWidth === clientWidth.
    expect(wrapperElement.scrollWidth).toBeLessThanOrEqual(wrapperElement.clientWidth);
  });
});
