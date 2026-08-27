import { describe, it, expect } from 'vitest';
import { render } from 'vitest-browser-react';
import { page } from 'vitest/browser';
import { BlockCardL } from '../../../../lib/components/BlockWorkPackage/BlockCards';

const cardWp = {
  id: 81,
  displayId: '81',
  subject: 'Fix login bug',
  _links: {
    self: { href: '/api/v3/work_packages/81' },
    type: { title: 'BUG', href: '/api/v3/types/1' },
    status: { title: 'In progress', href: '/api/v3/statuses/1' },
    parent: { title: 'Parent WP', href: '/api/v3/work_packages/1' },
    project: { title: 'A project with a name long enough to need a line of its own', href: '/api/v3/projects/1' },
  },
};

function renderCard() {
  render(
    <div data-testid="card-host" style={{ width: 260 }}>
      <BlockCardL workPackage={cardWp} linkTitle />
    </div>,
  );
}

describe('Block card - meta line', () => {
  it('keeps the relation marker on the line of the label it marks', async () => {
    renderCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();

    const metaItems = page.getByTestId('block-card').element().querySelectorAll('.op-bn-work-package--details > span:not([class*="op-bn-work-package--"])');
    const [parent, project] = Array.from(metaItems).slice(-2);

    expect(parent.textContent).toBe('↑\u00A0Parent WP');
    expect(project.textContent).toBe(`◈\u00A0${cardWp._links.project.title}`);
  });

  it('wraps a long relation title instead of overflowing the card', async () => {
    renderCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();

    const card = page.getByTestId('block-card').element();
    const details = card.querySelector('.op-bn-work-package--details')!;

    expect(details.scrollWidth).toBeLessThanOrEqual(details.clientWidth);
    expect(card.getBoundingClientRect().right)
      .toBeLessThanOrEqual(page.getByTestId('card-host').element().getBoundingClientRect().right);
  });
});
