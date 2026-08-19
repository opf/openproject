/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';
import { useMatchMedia } from 'stimulus-use';
import { OpColorMode, OpTheme } from 'core-app/core/setup/globals/theme-utils';

export default class AutoThemeSwitcher extends Controller {
  static values = {
    theme: String,
    increaseContrast: Boolean,
    forceLightContrast: Boolean,
    forceDarkContrast: Boolean,
  };

  static targets = ['desktopLogo', 'mobileLogo'];
  static classes = ['desktopLightHighContrastLogo', 'mobileWhiteLogo'];

  declare readonly themeValue:OpTheme;
  declare readonly increaseContrastValue:boolean;
  declare readonly forceLightContrastValue:boolean;
  declare readonly forceDarkContrastValue:boolean;
  declare readonly desktopLogoTarget:HTMLLinkElement;
  declare readonly mobileLogoTarget:HTMLLinkElement;
  declare readonly desktopLightHighContrastLogoClass:string;
  declare readonly mobileWhiteLogoClass:string;
  declare readonly hasMobileLogoTarget:boolean;
  declare readonly hasDesktopLogoTarget:boolean;

  private colorModeContrastPreferences:Record<OpColorMode, boolean>;

  connect() {
    if (this.themeValue === 'sync_with_os') {
      this.syncWithOS();
    } else {
      this.applyTheme(this.themeValue, this.increaseContrastValue);
    }
  }

  syncWithOS():void {
    this.colorModeContrastPreferences = {
      light: this.forceLightContrastValue,
      dark: this.forceDarkContrastValue,
    };

    useMatchMedia(this, {
      mediaQueries: {
        lightMode: '(prefers-color-scheme: light)',
        highContrastMode: '(prefers-contrast: more)',
      },
    });

    this.applySystemTheme();
  }

  applyTheme(theme:OpColorMode, increaseContrast:boolean):void {
    window.OpenProject.theme.applyThemeToBody(theme, increaseContrast);
    this.updateOpLogoContrast(theme, increaseContrast);
  }

  lightModeChanged():void {
    this.applySystemTheme();
  }

  highContrastModeChanged():void {
    this.applySystemTheme();
  }

  private applySystemTheme():void {
    const colorMode = window.OpenProject.theme.detectSystemColorMode();
    const prefersSystemHighContrast = window.OpenProject.theme.prefersSystemHighContrast();
    const increaseContrast = prefersSystemHighContrast || this.colorModeContrastPreferences[colorMode];

    this.applyTheme(colorMode, increaseContrast);
  }

  private updateOpLogoContrast(colorMode:OpColorMode, increaseContrast:boolean):void {
    const isLightHighContrast = (colorMode === 'light' && increaseContrast);

    // Some layouts do not show a logo
    if (this.hasDesktopLogoTarget) {
      this.desktopLogoTarget.classList.toggle(this.desktopLightHighContrastLogoClass, isLightHighContrast);
    }

    // Custom logos are not supported on mobile
    if (this.hasMobileLogoTarget) {
      this.mobileLogoTarget.classList.toggle(this.mobileWhiteLogoClass, !isLightHighContrast);
    }
  }
}
