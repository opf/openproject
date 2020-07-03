import {wpOnboardingTourSteps} from "core-app/globals/onboarding/tours/work_package_tour";
import {
  demoProjectsLinks,
  onboardingTourStorageKey,
  preventClickHandler,
  waitForElement
} from "core-app/globals/onboarding/helpers";
import {boardTourSteps} from "core-app/globals/onboarding/tours/boards_tour";
import {menuTourSteps} from "core-app/globals/onboarding/tours/menu_tour";
import {homescreenOnboardingTourSteps} from "core-app/globals/onboarding/tours/homescreen_tour";
import {scrumBacklogsTourSteps, scrumTaskBoardTourSteps} from "core-app/globals/onboarding/tours/backlogs_tour";

require('core-vendor/enjoyhint');

export function start(name:string) {
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
  window.onboardingTourInstance = new (window as any).EnjoyHint({
    onStart: function () {
      jQuery('#content-wrapper, #menu-sidebar').addClass('-hidden-overflow');
    },
    onEnd: function () {
      sessionStorage.setItem(onboardingTourStorageKey, storageValue);
      jQuery('#content-wrapper, #menu-sidebar').removeClass('-hidden-overflow');
    },
    onSkip: function () {
      sessionStorage.setItem(onboardingTourStorageKey, 'skipped');
      if (disabledElements) {
        jQuery(disabledElements).removeClass('-disabled').unbind('click', preventClickHandler);
      }
      if (projectSelection) {
        $.each(demoProjectsLinks(), function (i, e) {
          jQuery(e).off('click');
        });
      }
      jQuery('#content-wrapper, #menu-sidebar').removeClass('-hidden-overflow');
    }
  });
}

function startTour(steps:any) {
  window.onboardingTourInstance.set(steps);
  window.onboardingTourInstance.run();
}

function mainTour() {
  initializeTour('mainTourFinished');

  const boardsDemoDataAvailable = $('meta[name=boards_demo_data_available]').attr('content') === "true";
  const eeTokenAvailable = !$('body').hasClass('ee-banners-visible');

  waitForElement('.work-package--results-tbody', '#content', function () {
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
