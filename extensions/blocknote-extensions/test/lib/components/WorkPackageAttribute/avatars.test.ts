import { describe, it, expect } from 'vitest';
import { avatarColorOf, initialsOf } from '../../../../lib/components/WorkPackageAttribute/avatars';

describe('initialsOf', () => {
  it('takes the first letters of the first and the last name', () => {
    expect(initialsOf('Mira Hofmann')).toBe('MH');
    expect(initialsOf('jean de la cruz')).toBe('JC');
  });

  it('takes one letter of a single name', () => {
    expect(initialsOf('admin')).toBe('A');
  });

  it('keeps an emoji whole', () => {
    expect(initialsOf('🦊 Fox')).toBe('🦊F');
  });
});

describe('avatarColorOf', () => {
  it('gives the color OpenProject gives the same person', () => {
    expect(avatarColorOf({ name: 'Mira Hofmann', href: '/api/v3/users/3' })).toBe('hsl(-183, 50%, 30%)');
  });

  it('tells two people of the same name apart', () => {
    expect(avatarColorOf({ name: 'Mira Hofmann', href: '/api/v3/users/4' }))
      .not.toBe(avatarColorOf({ name: 'Mira Hofmann', href: '/api/v3/users/3' }));
  });
});
