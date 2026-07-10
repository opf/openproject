import * as Turbo from '@hotwired/turbo';
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
import { WP_ID_URL_PATTERN } from 'core-app/shared/helpers/work-package-id-pattern';
import { isOpenProjectCustomElement } from './openproject-custom-element';

// `view` exists on the Turbo session at runtime but is absent from the project's
// hand-written @types/hotwired__turbo typings; narrow-cast here, same precedent
// as turbo/helpers.ts and turbo-navigation-patch.ts.
interface TurboSessionWithView extends Turbo.TurboSession {
  view:{ lastRenderedLocation:URL };
}

// Compiled once: matches a work package id anywhere in the pathname, reusing the
// shared WP_ID_URL_PATTERN so numeric ("42") and semantic ("PROJ-42") ids both match.
const workPackageIdPathPattern = new URLPattern({
  pathname: `{*}/work_packages/:id(${WP_ID_URL_PATTERN}){/*}?`,
});

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

export function canonicalizeWorkPackageIdInUrl():void {
  const currentPath = window.location.pathname;
  const currentId = workPackageIdPathPattern.exec({ pathname: currentPath })?.pathname.groups.id;
  if (!currentId) return;

  const canonical = document.querySelector<HTMLLinkElement>('link[rel="canonical"]');
  if (!canonical?.href) return;

  const canonicalPath = new URL(canonical.href).pathname;
  const canonicalId = workPackageIdPathPattern.exec({ pathname: canonicalPath })?.pathname.groups.id;
  if (!canonicalId || canonicalId === currentId) return;

  const newPath = currentPath.replace(`/work_packages/${currentId}`, `/work_packages/${canonicalId}`);
  const newUrl = new URL(newPath + window.location.search + window.location.hash, window.location.origin);

  // Use Turbo's history.replace (not window.history.replaceState) so Turbo's internal
  // location stays in sync — otherwise back/forward popstate resolves the stale URL.
  // Pass the current restorationIdentifier explicitly: History.replace defaults to a
  // fresh uuid, orphaning the recorded scroll-restoration data.
  Turbo.session.history.replace(newUrl, Turbo.session.history.restorationIdentifier);
  // PageView#cacheSnapshot keys the snapshot cache by lastRenderedLocation; left stale,
  // back/forward misses the cache and re-fetches instead of restoring instantly.
  (Turbo.session as TurboSessionWithView).view.lastRenderedLocation = newUrl;
}
