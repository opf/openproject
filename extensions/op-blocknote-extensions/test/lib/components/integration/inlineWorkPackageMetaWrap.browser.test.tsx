import { describe, it, expect } from 'vitest';
import { render } from 'vitest-browser-react';
import { page } from 'vitest/browser';
import { WpChipXS, WpChipS } from '../../../../lib/components/InlineWorkPackage/InlineChips';
import { mockWorkPackage } from '../../../mocks/handlers';

// Container narrow enough that the meta cluster (#ID TYPE [STATUS]) cannot sit on a single
// line, but wide enough for the widest single part. Each part is `white-space: nowrap`, so the
// only way to avoid horizontal overflow is to wrap *between* parts. Before the fix the parts
// had no soft-wrap opportunity between them and the cluster overflowed; now a zero-width space
// between parts lets it wrap. The S chip has the extra (wide) status pill, so it needs more
// room for its widest single part than the XS chip does.
const S_NARROW_WIDTH = '110px';
const XS_NARROW_WIDTH = '80px';

describe('InlineChips - wrap between meta parts', () => {
  it('WpChipS wraps between parts instead of overflowing a narrow container', async () => {
    render(
      <div data-testid="narrow-wrapper" style={{ width: S_NARROW_WIDTH }}>
        <WpChipS wp={mockWorkPackage} />
      </div>
    );

    const wrapperLocator = page.getByTestId('narrow-wrapper');
    await expect.element(wrapperLocator).toBeVisible();
    // All parts remain fully visible — wrapping between them, never truncating within them.
    await expect.element(page.getByText(`#${mockWorkPackage.displayId}`)).toBeVisible();
    await expect.element(page.getByText(mockWorkPackage._links.status.title)).toBeVisible();
    await expect.element(page.getByText(mockWorkPackage.subject)).toBeVisible();

    const wrapperElement = await wrapperLocator.element();
    // scrollWidth > clientWidth means the chip overflows horizontally (the meta cluster could
    // not break). Wrapping between parts keeps scrollWidth === clientWidth.
    expect(wrapperElement.scrollWidth).toBeLessThanOrEqual(wrapperElement.clientWidth);
  });

  it('WpChipXS wraps between parts instead of overflowing a narrow container', async () => {
    render(
      <div data-testid="narrow-wrapper" style={{ width: XS_NARROW_WIDTH }}>
        <WpChipXS wp={mockWorkPackage} />
      </div>
    );

    const wrapperLocator = page.getByTestId('narrow-wrapper');
    await expect.element(wrapperLocator).toBeVisible();
    await expect.element(page.getByText(`#${mockWorkPackage.displayId}`)).toBeVisible();
    await expect.element(page.getByText(mockWorkPackage.subject)).toBeVisible();

    const wrapperElement = await wrapperLocator.element();
    expect(wrapperElement.scrollWidth).toBeLessThanOrEqual(wrapperElement.clientWidth);
  });
});
