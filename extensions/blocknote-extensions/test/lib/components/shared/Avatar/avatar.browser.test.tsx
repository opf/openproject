import { describe, expect, it } from 'vitest';
import { render } from 'vitest-browser-react';
import { Avatar } from '../../../../../lib/components/shared/Avatar';

async function renderAvatar(userId:number, name:string) {
  const { container } = await render(<Avatar userId={userId} name={name} size={16} />);
  const avatar = container.querySelector<HTMLElement>('.op-bn-avatar')!;
  return { avatar, picture: avatar.querySelector('img')! };
}

describe('Avatar', () => {
  it('shows the uploaded picture instead of the initials once it has loaded', async () => {
    const { avatar, picture } = await renderAvatar(7, 'Anna Kovalenko');

    await expect.element(picture).toBeVisible();
    await expect.element(avatar).not.toHaveTextContent('AK');
  });

  it('keeps the initials when the user has no avatar', async () => {
    const { avatar, picture } = await renderAvatar(8, 'Peter Lang');

    await expect.poll(() => picture.complete).toBe(true);
    expect(picture.naturalWidth).toBe(0);

    await expect.element(avatar).toHaveTextContent('PL');
    await expect.element(picture).not.toBeVisible();
  });

  it('hides the avatar from screen readers', async () => {
    const { avatar } = await renderAvatar(8, 'Peter Lang');

    expect(avatar.getAttribute('aria-hidden')).toBe('true');
    expect(avatar.hasAttribute('role')).toBe(false);
    expect(avatar.hasAttribute('aria-label')).toBe(false);
    expect(avatar.hasAttribute('title')).toBe(false);
  });
});
