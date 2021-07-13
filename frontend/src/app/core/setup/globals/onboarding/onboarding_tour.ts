import { wpOnboardingTourSteps } from 'core-app/core/setup/globals/onboarding/tours/work_package_tour';
import {
  demoProjectsLinks,
  OnboardingTourNames,
  onboardingTourStorageKey,
  preventClickHandler,
  waitForElement,
} from 'core-app/core/setup/globals/onboarding/helpers';
import { boardTourSteps } from 'core-app/core/setup/globals/onboarding/tours/boards_tour';
import { menuTourSteps } from 'core-app/core/setup/globals/onboarding/tours/menu_tour';
import { homescreenOnboardingTourSteps } from 'core-app/core/setup/globals/onboarding/tours/homescreen_tour';
import {
  scrumBacklogsTourSteps,
  scrumTaskBoardTourSteps,
} from 'core-app/core/setup/globals/onboarding/tours/backlogs_tour';

require('core-vendor/enjoyhint');

declare global {
  interface Window {
    EnjoyHint:any;
  }
}

export function start(name:OnboardingTourNames) {
  console.log('star tour', name);
  switch (name) {
    case 'backlogs':
      initializeTour('startTaskBoardTour');
      startTour(scrumBacklogsTourSteps());
      break;
    case 'taskboard':
      initializeTour('startMainTourFromBacklogs');
      startTour(scrumTaskBoardTourSteps());
      break;
    case 'homescreen':
      initializeTour('startProjectTour', '.widget-box--blocks--buttons a', true);
      startTour(homescreenOnboardingTourSteps());
      break;
    case 'main':
      mainTour();
      break;
  }
}

function initializeTour(storageValue:any, disabledElements?:any, projectSelection?:any) {
  window.onboardingTourInstance = new window.EnjoyHint({
    onStart() {
      jQuery('#content-wrapper, #menu-sidebar').addClass('-hidden-overflow');
    },
    onEnd() {
      sessionStorage.setItem(onboardingTourStorageKey, storageValue);
      jQuery('#content-wrapper, #menu-sidebar').removeClass('-hidden-overflow');
    },
    onSkip() {
      sessionStorage.setItem(onboardingTourStorageKey, 'skipped');
      if (disabledElements) {
        jQuery(disabledElements).removeClass('-disabled').unbind('click', preventClickHandler);
      }
      if (projectSelection) {
        jQuery.each(demoProjectsLinks(), (i, e) => {
          jQuery(e).off('click');
        });
      }
      jQuery('#content-wrapper, #menu-sidebar').removeClass('-hidden-overflow');
    },
  });
}

function startTour(steps:any) {
  console.log('startTour', steps);
  window.onboardingTourInstance.set(steps);
  window.onboardingTourInstance.run();
}

function mainTour() {
  initializeTour('mainTourFinished');

  const boardsDemoDataAvailable = jQuery('meta[name=boards_demo_data_available]').attr('content') === 'true';
  const eeTokenAvailable = !jQuery('body').hasClass('ee-banners-visible');

  waitForElement('.work-package--results-tbody', '#content', () => {
    let steps:any[];

    // Check for EE edition, and available seed data of boards.
    // Then add boards to the tour, otherwise skip it.
    if (eeTokenAvailable && boardsDemoDataAvailable) {
      steps = wpOnboardingTourSteps().concat(boardTourSteps()).concat(menuTourSteps());
    } else {
      steps = wpOnboardingTourSteps().concat(menuTourSteps());
    }

    startTour(steps);
  });
}
