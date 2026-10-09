import { describe, it, expect } from 'vitest';
import { page } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { mentionContent, paragraphWith } from '../../../helpers/content';

function mentionParts(name:string) {
  const link = page.getByRole('link', { name }).element();
  const pill = link.closest('.op-bn-user-mention');
  const avatar = pill?.querySelector('.op-bn-avatar');
  if (!pill || !avatar) throw new Error(`mention of ${name} did not render`);

  const pillBox = pill.getBoundingClientRect();
  const avatarBox = avatar.getBoundingClientRect();
  return {
    above: pillBox.top - avatarBox.top,
    below: avatarBox.bottom - pillBox.bottom,
    offset: avatarBox.top - pillBox.top,
    gap: link.getBoundingClientRect().left - avatarBox.right,
  };
}

describe('User mention - the avatar sits inside the pill', () => {
  it('keeps picture and initials avatars at the same height, inside the pill, 4px from the name', async () => {
    renderEditor({
      initialContent: [paragraphWith(mentionContent('7', 'Anna Kovalenko'), ' and ', mentionContent('8', 'Peter Lang'))],
    });

    await expect.element(page.getByRole('link', { name: 'Peter Lang' })).toBeVisible();
    const annaPicture = page.getByRole('button', { name: 'User Anna Kovalenko' }).element().querySelector('img')!;
    await expect.element(annaPicture).toBeVisible();
    await document.fonts.load('500 12px Inter');
    await document.fonts.load('600 7px Inter');
    expect(document.fonts.check('500 12px Inter')).toBe(true);

    const picture = mentionParts('Anna Kovalenko');
    const initials = mentionParts('Peter Lang');

    for (const [label, parts] of [['picture', picture], ['initials', initials]] as const) {
      expect.soft(parts.above, `${label} avatar sticks ${parts.above.toFixed(2)}px above the pill`).toBeLessThanOrEqual(0.5);
      expect.soft(parts.below, `${label} avatar hangs ${parts.below.toFixed(2)}px below the pill`).toBeLessThanOrEqual(0.5);
      expect.soft(Math.abs(parts.gap - 4), `${label} avatar is ${parts.gap.toFixed(2)}px from the name`).toBeLessThanOrEqual(0.5);
    }
    expect.soft(
      Math.abs(picture.offset - initials.offset),
      `picture avatar at ${picture.offset.toFixed(2)}px, initials at ${initials.offset.toFixed(2)}px`,
    ).toBeLessThanOrEqual(0.5);
  });
});
