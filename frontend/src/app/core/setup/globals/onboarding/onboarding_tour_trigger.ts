// Dynamically loads and triggers the onboarding tour
// when on the correct spots
import {
  OnboardingTourNames,
  onboardingTourStorageKey,
  waitForElement,
} from 'core-app/core/setup/globals/onboarding/helpers';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { getMetaContent } from '../global-helpers';

async function triggerTour(name:OnboardingTourNames):Promise<void> {
  debugLog(`Loading and triggering onboarding tour ${name}`);

  const pluginContext = await window.OpenProject.getPluginContext();
  const configuration = pluginContext.services.configurationService;

  // Wait for configuration to be loaded
  await configuration.initialize();

  await import('./onboarding_tour').then((tour) => {
    tour.start(name, configuration);
  });
}

export function detectOnboardingTour():void {
  // ------------------------------- Global -------------------------------
  const url = new URL(window.location.href);
  const isMobile = document.body.classList.contains('-browser-mobile');
  const demoProjectsAvailable = getMetaContent('demo_projects_available') === 'true';
  let currentTourPart = sessionStorage.getItem(onboardingTourStorageKey);
  let tourCancelled = false;

  // ------------------------------- Initial start -------------------------------
  // Do not show the tutorial on mobile or when the demo data has been deleted
  if (!isMobile && demoProjectsAvailable) {
    // Start after the intro modal (language selection)
    // This has to be changed once the project selection is implemented
    if (url.searchParams.get('first_time_user')) {
      currentTourPart = '';
      sessionStorage.setItem(onboardingTourStorageKey, 'readyToStart');

      // Start automatically when modal is closed by backdrop click or cancel button
      waitForElement('.spot-modal-overlay_active', 'body', () => {
        const elementsByClassName = document.getElementsByClassName('spot-modal-overlay_active');
        Array.from(elementsByClassName).forEach((modalOverlay) => {
          modalOverlay.addEventListener('click', (evt) => {
            if (evt.target === modalOverlay) {
              tourCancelled = true;
              void triggerTour('homescreen');
            }
          });

          document.querySelector('[data-tour-selector="modal-close-button"]')?.addEventListener('click', () => {
            tourCancelled = true;
            void triggerTour('homescreen');
          });
        });
      });

      // Start automatically when the escape button is pressed
      document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && !tourCancelled) {
          tourCancelled = true;
          void triggerTour('homescreen');
        }
      }, { once: true });
    }

    // ------------------------------- Tutorial Homescreen page -------------------------------
    // start the home onboarding tour (either after the intro modal or by parameter)
    if (currentTourPart === 'readyToStart' || url.searchParams.get('start_home_onboarding_tour')) {
      void triggerTour('homescreen');
    }

    // ------------------------------- Tutorial WP page -------------------------------
    if (url.searchParams.get('start_onboarding_tour')) {
      void triggerTour('workPackages');
    }

    // ------------------------------- Tutorial WP Full page -------------------------------
    if (currentTourPart === 'wpTourFinished') {
      void triggerTour('workPackagesFullView');
    }

    // ------------------------------- Tutorial Gantt module -------------------------------
    if (currentTourPart === 'wpFullViewTourFinished') {
      void triggerTour('gantt');
      return;
    }

    // ------------------------------- Tutorial Boards module -------------------------------
    if (currentTourPart === 'ganttTourFinished') {
      if (url.pathname.includes('boards')) {
        void triggerTour('boards');
        return;
      }
      if (url.pathname.includes('team_planner')) {
        void triggerTour('teamPlanner');
        return;
      }
      void triggerTour('final');
    }

    // ------------------------------- Tutorial TeamPlanner module -------------------------------
    if (currentTourPart === 'boardsTourFinished') {
      if (url.pathname.includes('team_planner')) {
        void triggerTour('teamPlanner');
        return;
      }
      void triggerTour('final');
    }

    // ------------------------------- Fina tutorial  -------------------------------
    if (currentTourPart === 'teamPlannerTourFinished') {
      void triggerTour('final');
    }
  }
}
