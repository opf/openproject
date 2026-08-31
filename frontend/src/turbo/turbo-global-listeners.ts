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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { DeviceService } from 'core-app/core/browser/device.service';
import { scrollHeaderOnMobile } from 'core-app/core/setup/globals/global-listeners/top-menu-scroll';
import { detectOnboardingTour } from 'core-app/core/setup/globals/onboarding/onboarding_tour_trigger';
import { installMenuLogic } from 'core-app/core/setup/globals/global-listeners/action-menu';
import { makeColorPreviews } from 'core-app/core/setup/globals/global-listeners/color-preview';
import { fixFragmentAnchors } from 'core-app/core/setup/globals/global-listeners/fix-fragment-anchors';
import {
  activateFlashError,
  activateFlashNotice,
  focusFirstErroneousField,
  initMainMenuExpandStatus,
} from 'core-app/core/setup/globals/global-listeners/setup-server-response';
import { canonicalizeWorkPackageIdInUrl } from 'core-app/core/setup/globals/canonicalize-work-package-id-in-url';
import { isOpenProjectCustomElement } from './openproject-custom-element';

export function addTurboGlobalListeners(target:Document = document, signal?:AbortSignal) {
  const runOnRenderAndLoad = () => {
    // Add to content if warnings displayed
    if (target.querySelector('.warning-bar--item')) {
      const content = target.querySelector<HTMLElement>('#content');
      if (content) {
        content.style.marginBottom = '100px';
      }
    }

    const deviceService:DeviceService = new DeviceService();
    // Register scroll handler on mobile header
    if (deviceService.isMobile) {
      scrollHeaderOnMobile();
    }

    // Detect and trigger the onboarding tour
    // through a lazy loaded script
    detectOnboardingTour();

    //
    // Legacy scripts from app/assets that are not yet component based
    //

    // Action menu logic
    target.querySelectorAll<HTMLElement>('.toolbar-items').forEach((menu) => {
      installMenuLogic(menu);
    });

    // Color patches preview the color
    makeColorPreviews();

    // Replace fragment
    fixFragmentAnchors();

    // Legacy server response setup
    initMainMenuExpandStatus();
    focusFirstErroneousField();
    activateFlashNotice();
    activateFlashError();

    // Ensure the URL contains the correct work package identifier
    canonicalizeWorkPackageIdInUrl();
  };
  target.addEventListener('turbo:render', runOnRenderAndLoad, { signal });
  target.addEventListener('DOMContentLoaded', runOnRenderAndLoad, { signal });

  target.addEventListener('turbo:before-morph-element', (event) => {
    // In case the element is an OpenProject custom dom element, morphing is prevented.
    if (isOpenProjectCustomElement(event.target)) {
      event.preventDefault();
    }
  }, { signal });
}
