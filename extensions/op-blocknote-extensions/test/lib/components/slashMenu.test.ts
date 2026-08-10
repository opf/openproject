// @vitest-environment jsdom

import { describe, it, expect } from 'vitest';
import { getOpenProjectSlashMenuItems } from '../../../lib/components/SlashMenu';
import i18n from '../../../lib/services/i18n';

const setLang = async (lang:string) => i18n.changeLanguage(lang);

describe('getOpenProjectSlashMenuItems', () => {
  const linkItem = () => getOpenProjectSlashMenuItems({} as any)[0];
  const createItem = () => getOpenProjectSlashMenuItems({} as any)[1];

  it('is translated to German', async () => {
    await setLang('de');
    const slashMenu = linkItem();
    expect(slashMenu.title).toBe('Vorhandenes Arbeitspaket verlinken');
  });

  it('is translated to English', async () => {
    await setLang('en');
    const slashMenu = linkItem();
    expect(slashMenu.title).toBe('Link existing work package');
  });

  it('calculates all possible aliases for the slash menu', async () => {
    await setLang('en');
    const slashMenu = linkItem();
    const actual = slashMenu.aliases;
    const expected = [
      'openproject work package link', 'openproject workpackage link', 'openproject wp link',
      'op work package link', 'op workpackage link', 'op wp link',
      'openproject link work package', 'openproject link workpackage', 'openproject link wp',
      'op link work package', 'op link workpackage', 'op link wp',
      'work package openproject link', 'work package op link',
      'workpackage openproject link', 'workpackage op link',
      'wp openproject link', 'wp op link',
      'work package link openproject', 'work package link op',
      'workpackage link openproject', 'workpackage link op',
      'wp link openproject', 'wp link op',
      'link work package openproject', 'link work package op',
      'link workpackage openproject', 'link workpackage op',
      'link wp openproject', 'link wp op',
      'link openproject work package', 'link openproject workpackage', 'link openproject wp',
      'link op work package', 'link op workpackage', 'link op wp',
    ];
    expect(actual.sort()).toEqual(expected.sort());
  });

  it('keeps English aliases even when language is German', async () => {
    await setLang('de');
    const slashMenu = linkItem();
    const actual = slashMenu.aliases;

    expect(actual).toContain('openproject work package link');
    expect(actual).toContain('openproject Arbeitspaket link');
    expect(actual).toContain('openproject wp link');
    expect(actual).toContain('openproject ap link');

    await setLang('en');
  });

  it('offers the create item next to the link item', async () => {
    await setLang('en');
    const items = getOpenProjectSlashMenuItems({} as any);

    expect(items.map((item) => item.title))
      .toEqual(['Link existing work package', 'Create new work package']);
    expect(createItem().aliases).toContain('openproject work package create');
  });
});
