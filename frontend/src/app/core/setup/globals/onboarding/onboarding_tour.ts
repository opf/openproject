import { wpOnboardingTourSteps } from 'core-app/core/setup/globals/onboarding/tours/work_package_tour';
import {
  OnboardingTourNames,
  onboardingTourStorageKey,
  waitForElement,
} from 'core-app/core/setup/globals/onboarding/helpers';
import {
  boardTourSteps,
  navigateToBoardStep,
} from 'core-app/core/setup/globals/onboarding/tours/boards_tour';
import { menuTourSteps } from 'core-app/core/setup/globals/onboarding/tours/menu_tour';
import { homescreenOnboardingTourSteps } from 'core-app/core/setup/globals/onboarding/tours/homescreen_tour';
import {
  navigateToTeamPlannerStep,
  teamPlannerTourSteps,
} from 'core-app/core/setup/globals/onboarding/tours/team_planners_tour';
import { ganttOnboardingTourSteps } from 'core-app/core/setup/globals/onboarding/tours/gantt_tour';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

import 'core-vendor/enjoyhint';
import { wpFullViewOnboardingTourSteps } from 'core-app/core/setup/globals/onboarding/tours/work_package_full_view_tour';
import { getMetaContent } from '../global-helpers';

declare global {
  interface Window {
    EnjoyHint:any;
  }
}

export interface OnboardingStep {
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
}

function initializeTour(storageValue:string) {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-call,@typescript-eslint/no-unsafe-assignment
  window.onboardingTourInstance = new window.EnjoyHint({
    onStart() {
      document.querySelectorAll('#content-wrapper, #menu-sidebar')
        .forEach((elem) => elem.classList.add('-hidden-overflow'));
      sessionStorage.setItem(onboardingTourStorageKey, storageValue);
    },
    onEnd() {
      sessionStorage.setItem(onboardingTourStorageKey, storageValue);
      document.querySelectorAll('#content-wrapper, #menu-sidebar')
        .forEach((elem) => elem.classList.remove('-hidden-overflow'));
    },
    onSkip() {
      sessionStorage.setItem(onboardingTourStorageKey, 'skipped');
      document.querySelectorAll('#content-wrapper, #menu-sidebar')
        .forEach((elem) => elem.classList.remove('-hidden-overflow'));
    },
  });
}

function startTour(steps:OnboardingStep[]) {
  window.onboardingTourInstance.set(steps);
  window.onboardingTourInstance.run();
}

export function moduleVisible(name:string):boolean {
  return document.querySelector(`#menu-sidebar .${name}-menu-item`) !== null;
}

function workPackageTour() {
  initializeTour('wpTourFinished');
  waitForElement('.work-package--results-tbody', '#content', () => {
    const steps:OnboardingStep[] = wpOnboardingTourSteps();

    startTour(steps);
  });
}


function workPackageFullViewTour() {
  initializeTour('wpFullViewTourFinished');
  waitForElement('.work-package--single-view', '#content', () => {
    const steps:OnboardingStep[] = wpFullViewOnboardingTourSteps();

    startTour(steps);
  });
}

function ganttTour(_configuration:ConfigurationService) {
  initializeTour('ganttTourFinished');

  waitForElement('.work-package--results-tbody', '#content', () => {
    let steps:OnboardingStep[] = ganttOnboardingTourSteps();
    if (showBoardsTour()) {
      steps = steps.concat(navigateToBoardStep());
    } else if (showTeamPlannerTour(_configuration)) {
      steps = steps.concat(navigateToTeamPlannerStep());
    } else {
      steps = steps.concat(menuTourSteps());
    }

    startTour(steps);
  });
}

function boardTour(_configuration:ConfigurationService) {
  initializeTour('boardsTourFinished');


  waitForElement('wp-single-card', '#content', () => {
    let steps:OnboardingStep[] = boardTourSteps();

    // Available seed data of team planner.
    // Then add Team planner to the tour, otherwise skip it.
    if (showTeamPlannerTour(_configuration)) {
      steps = steps.concat(navigateToTeamPlannerStep());
    } else {
      steps = steps.concat(menuTourSteps());
    }

    startTour(steps);
  });
}

function teamPlannerTour() {
  initializeTour('teamPlannerTourFinished');
  waitForElement('full-calendar', '#content', () => {
    let steps:OnboardingStep[] = teamPlannerTourSteps();
    steps = steps.concat(menuTourSteps());

    startTour(steps);
  });
}

function showBoardsTour():boolean {
  const boardsDemoDataAvailable = getMetaContent('boards_demo_data_available') === 'true';

  return boardsDemoDataAvailable && moduleVisible('boards');
}

function showTeamPlannerTour(configuration:ConfigurationService):boolean {
  const eeTokenAvailable = configuration.availableFeatures.includes('team_planner_view');
  const teamPlannerDemoDataAvailable = getMetaContent('demo_view_of_type_team_planner_seeded') === 'true';

  return eeTokenAvailable && teamPlannerDemoDataAvailable && moduleVisible('team-planner-view');
}

export function start(name:OnboardingTourNames, configuration:ConfigurationService):void {
  switch (name) {
    case 'homescreen':
      initializeTour('startProjectTour');
      startTour(homescreenOnboardingTourSteps());
      break;
    case 'workPackages':
      workPackageTour();
      break;
    case 'workPackagesFullView':
      workPackageFullViewTour();
      break;
    case 'gantt':
      ganttTour(configuration);
      break;
    case 'boards':
      boardTour(configuration);
      break;
    case 'teamPlanner':
      teamPlannerTour();
      break;
    default:
      break;
  }
}
