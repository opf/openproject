// Dynamically loads and triggers the onboarding tour
// when on the correct spots
import { demoProjectsLinks, OnboardingTourNames, onboardingTourStorageKey } from "core-app/globals/onboarding/helpers";
import { debugLog } from "core-app/helpers/debug_output";

export function detectOnboardingTour() {
  // ------------------------------- Global -------------------------------
  const url = new URL(window.location.href);
  const isMobile = document.body.classList.contains('-browser-mobile');
  const demoProjectsAvailable = jQuery('meta[name=demo_projects_available]').attr('content') === "true";
  let currentTourPart = sessionStorage.getItem(onboardingTourStorageKey);
  let tourCancelled = false;

  // ------------------------------- Initial start -------------------------------
  // Do not show the tutorial on mobile or when the demo data has been deleted
  if (!isMobile && demoProjectsAvailable) {

    // Start after the intro modal (language selection)
    // This has to be changed once the project selection is implemented
    if (url.searchParams.get("first_time_user") && demoProjectsLinks().length === 2) {
      currentTourPart = '';
      sessionStorage.setItem(onboardingTourStorageKey, 'readyToStart');

      // Start automatically when the language selection is closed
      jQuery('.op-modal--close-button').click(function () {
        tourCancelled = true;
        triggerTour('homescreen');
      });

      //Start automatically when the escape button is pressed
      document.addEventListener('keydown', function (event) {
        if (event.key === "Escape" && !tourCancelled) {
          tourCancelled = true;
          triggerTour('homescreen');
        }
      }, { once: true });
    }

    // ------------------------------- Tutorial Homescreen page -------------------------------
    if (currentTourPart === "readyToStart") {
      triggerTour('homescreen');
    }

    // ------------------------------- Tutorial WP page -------------------------------
    if (currentTourPart === "startMainTourFromBacklogs" || url.searchParams.get("start_onboarding_tour")) {
      triggerTour('main');
    }

    // ------------------------------- Tutorial Backlogs page -------------------------------
    if (url.searchParams.get("start_scrum_onboarding_tour")) {
      if (jQuery('.backlogs-menu-item').length > 0) {
        triggerTour('backlogs');
      }
    }

    // ------------------------------- Tutorial Task Board page -------------------------------
    if (currentTourPart === "startTaskBoardTour") {
      triggerTour('taskboard');
    }
  }
}

async function triggerTour(name:OnboardingTourNames) {
  debugLog("Loading and triggering onboarding tour " + name);
  const tour = await import(/* webpackChunkName: "onboarding-tour" */ './onboarding_tour');
  tour.start(name);
}

