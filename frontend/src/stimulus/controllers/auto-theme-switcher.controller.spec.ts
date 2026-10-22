//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Application } from '@hotwired/stimulus';
import { vi } from 'vitest';
import { OpenProject } from 'core-app/core/setup/globals/openproject';
import { nextFrame } from 'core-common/testing/timing';
import AutoThemeSwitcher from './auto-theme-switcher.controller';

interface Fixture {
  name:string;
  light:boolean;
  contrastMore:boolean;
  forceLight:boolean;
  forceDark:boolean;
  colorMode:string;
  theme:string;
  absentAttribute:string;
}

const controllerAttribute = 'data-controller';
const themeAttribute = 'data-auto-theme-switcher-theme-value';
const forceLightContrastAttribute = 'data-auto-theme-switcher-force-light-contrast-value';
const forceDarkContrastAttribute = 'data-auto-theme-switcher-force-dark-contrast-value';
const bodyAttributes = [
  controllerAttribute,
  themeAttribute,
  forceLightContrastAttribute,
  forceDarkContrastAttribute,
  'data-color-mode',
  'data-light-theme',
  'data-dark-theme',
];

const fixtures:Fixture[] = [
  { name: 'dark', light: false, contrastMore: false, forceLight: false, forceDark: false, colorMode: 'dark', theme: 'dark', absentAttribute: 'data-light-theme' },
  { name: 'light', light: true, contrastMore: false, forceLight: false, forceDark: false, colorMode: 'light', theme: 'light', absentAttribute: 'data-dark-theme' },
  { name: 'dark with prefers-contrast: more', light: false, contrastMore: true, forceLight: false, forceDark: false, colorMode: 'dark', theme: 'dark_high_contrast', absentAttribute: 'data-light-theme' },
  { name: 'light with forced light contrast', light: true, contrastMore: false, forceLight: true, forceDark: false, colorMode: 'light', theme: 'light_high_contrast', absentAttribute: 'data-dark-theme' },
  { name: 'dark with forced dark contrast', light: false, contrastMore: false, forceLight: false, forceDark: true, colorMode: 'dark', theme: 'dark_high_contrast', absentAttribute: 'data-light-theme' },
  { name: 'light ignoring forced dark contrast', light: true, contrastMore: false, forceLight: false, forceDark: true, colorMode: 'light', theme: 'light', absentAttribute: 'data-dark-theme' },
  { name: 'dark ignoring forced light contrast', light: false, contrastMore: false, forceLight: true, forceDark: false, colorMode: 'dark', theme: 'dark', absentAttribute: 'data-light-theme' },
];

describe('AutoThemeSwitcher', () => {
  let originalOpenProject:OpenProject;
  let application:Application;

  beforeEach(() => {
    originalOpenProject = window.OpenProject;
    window.OpenProject = new OpenProject();
  });

  afterEach(() => {
    application?.unload('auto-theme-switcher');
    application?.stop();
    bodyAttributes.forEach((name) => document.body.removeAttribute(name));
    window.OpenProject = originalOpenProject;
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  function stubMatchMedia(light:boolean, contrastMore:boolean) {
    vi.stubGlobal('matchMedia', (query:string) => ({
      matches: query === '(prefers-color-scheme: light)' ? light : query === '(prefers-contrast: more)' && contrastMore,
      media: query,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
    }));
  }

  it.each(fixtures)('stamps the body attributes for $name', async (fixture) => {
    stubMatchMedia(fixture.light, fixture.contrastMore);
    const body = document.body;
    body.setAttribute(controllerAttribute, 'auto-theme-switcher');
    body.setAttribute(themeAttribute, 'sync_with_os');
    body.setAttribute(forceLightContrastAttribute, String(fixture.forceLight));
    body.setAttribute(forceDarkContrastAttribute, String(fixture.forceDark));

    application = Application.start();
    application.register('auto-theme-switcher', AutoThemeSwitcher);
    await nextFrame();

    expect(body.getAttribute('data-color-mode')).toBe(fixture.colorMode);
    expect(body.getAttribute(`data-${fixture.colorMode}-theme`)).toBe(fixture.theme);
    expect(body.hasAttribute(fixture.absentAttribute)).toBe(false);
  });
});
