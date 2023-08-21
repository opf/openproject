import { wpOnboardingTourSteps } from 'core-app/core/setup/globals/onboarding/tours/work_package_tour';
import {
  demoProjectsLinks,
  OnboardingTourNames,
  onboardingTourStorageKey,
  preventClickHandler,
  ProjectName,
  waitForElement,
} from 'core-app/core/setup/globals/onboarding/helpers';
import { boardTourSteps } from 'core-app/core/setup/globals/onboarding/tours/boards_tour';
import { menuTourSteps } from 'core-app/core/setup/globals/onboarding/tours/menu_tour';
import { homescreenOnboardingTourSteps } from 'core-app/core/setup/globals/onboarding/tours/homescreen_tour';
import {
  prepareScrumBacklogsTourSteps,
  scrumBacklogsTourSteps,
  scrumTaskBoardTourSteps,
} from 'core-app/core/setup/globals/onboarding/tours/backlogs_tour';
import { teamPlannerTourSteps } from 'core-app/core/setup/globals/onboarding/tours/team_planners_tour';

require('core-vendor/enjoyhint');

declare global {
  interface Window {
    EnjoyHint:any;
  }
}

export type OnboardingStep = {
  [key:string]:string|unknown,
  event?:string,
  description?:string,
  selector?:string,
  showSkip?:boolean,
  skipButton?:{ className:string, text:string },
  nextButton?:{ text:string },
  containerClass?:string,
  clickable?:boolean,
  timeout?:() => Promise<void>,
  condition?:() => boolean,
  onNext?:() => void,
  onBeforeStart?:() => void,
};

function initializeTour(storageValue:string, disabledElements?:string, projectSelection?:boolean) {
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

function startTour(steps:OnboardingStep[]) {
  window.onboardingTourInstance.set(steps);
  window.onboardingTourInstance.run();
}

function moduleVisible(name:string):boolean {
  return document.getElementsByClassName(`${name}-menu-item`).length > 0;
}

function mainTour(project:ProjectName = ProjectName.demo) {
  initializeTour('mainTourFinished');

  const boardsDemoDataAvailable = jQuery('meta[name=boards_demo_data_available]').attr('content') === 'true';
  const teamPlannerDemoDataAvailable = jQuery('meta[name=demo_view_of_type_team_planner_seeded]').attr('content') === 'true';
  const eeTokenAvailable = !jQuery('body').hasClass('ee-banners-visible');

  waitForElement('.work-package--results-tbody', '#content', () => {
    let steps:OnboardingStep[] = wpOnboardingTourSteps();

    // Check for EE edition
    if (eeTokenAvailable) {
      // ... and available seed data of boards.
      // Then add boards to the tour, otherwise skip it.
      if (boardsDemoDataAvailable && moduleVisible('boards')) {
        steps = steps.concat(boardTourSteps('enterprise', project));
      }

      // ... same for team planners
      if (teamPlannerDemoDataAvailable && moduleVisible('team-planner-view')) {
        steps = steps.concat(teamPlannerTourSteps());
      }
    } else if (boardsDemoDataAvailable && moduleVisible('boards')) {
      steps = steps.concat(boardTourSteps('basic', project));
    }

    steps = steps.concat(menuTourSteps());

    startTour(steps);
  });
}

export function start(name:OnboardingTourNames, project?:ProjectName):void {
  switch (name) {
    case 'prepareBacklogs':
      initializeTour('prepareTaskBoardTour');
      startTour(prepareScrumBacklogsTourSteps());
      break;
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
      mainTour(project);
      break;
    default:
      break;
  }
}
