import { DeviceService } from 'core-app/core/browser/device.service';
import { scrollHeaderOnMobile } from 'core-app/core/setup/globals/global-listeners/top-menu-scroll';
import { detectOnboardingTour } from 'core-app/core/setup/globals/onboarding/onboarding_tour_trigger';
import { installMenuLogic } from 'core-app/core/setup/globals/global-listeners/action-menu';
import { makeColorPreviews } from 'core-app/core/setup/globals/global-listeners/color-preview';
import { dangerZoneValidation } from 'core-app/core/setup/globals/global-listeners/danger-zone-validation';
import { fixFragmentAnchors } from 'core-app/core/setup/globals/global-listeners/fix-fragment-anchors';
import {
  activateFlashError,
  activateFlashNotice,
  focusFirstErroneousField,
  initMainMenuExpandStatus,
} from 'core-app/core/setup/globals/global-listeners/setup-server-response';

export function addTurboGlobalListeners() {
  const runOnRenderAndLoad = () => {
    // Add to content if warnings displayed
    if (document.querySelector('.warning-bar--item')) {
      const content = document.querySelector<HTMLElement>('#content');
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
    document.querySelectorAll<HTMLElement>('.toolbar-items').forEach((menu) => {
      installMenuLogic(menu);
    });

    // Color patches preview the color
    makeColorPreviews();

    // Danger zone input validation
    dangerZoneValidation();

    // Replace fragment
    fixFragmentAnchors();

    // Legacy server response setup
    initMainMenuExpandStatus();
    focusFirstErroneousField();
    activateFlashNotice();
    activateFlashError();
  };
  document.addEventListener('turbo:render', runOnRenderAndLoad);
  document.addEventListener('DOMContentLoaded', runOnRenderAndLoad);

  document.addEventListener('turbo:before-morph-element', (event) => {
    const element = event.target as HTMLElement;

    // In case the element is an OpenProject custom dom element, morphing is prevented.
    if (element.tagName.toUpperCase().startsWith('OPCE-')) {
      event.preventDefault();
    }
  });
}
