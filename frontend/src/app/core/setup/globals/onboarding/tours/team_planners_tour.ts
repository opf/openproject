import { waitForElement } from 'core-app/core/setup/globals/onboarding/helpers';
import { OnboardingStep } from 'core-app/core/setup/globals/onboarding/onboarding_tour';

export function teamPlannerTourSteps():OnboardingStep[] {
  return [
    {
      'next [data-tour-selector="op-team-planner--calendar-pane"]': I18n.t('js.onboarding.steps.team_planner.calendar'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      containerClass: '-dark -hidden-arrow',
      timeout: () => new Promise((resolve) => {
        waitForElement('.op-wp-single-card', '#content', () => {
          resolve(undefined);
        });
      }),
    },
    {
      'next [data-tour-selector="tp-assignee-add-button"]': I18n.t('js.onboarding.steps.team_planner.add_assignee'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
    },
    {
      'next [data-tour-selector="op-team-planner--add-existing-toggle"]': I18n.t('js.onboarding.steps.team_planner.add_existing'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
    },
    {
      'next [data-tour-selector="op-wp-single-card"]': I18n.t('js.onboarding.steps.team_planner.card'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        const teamPlannerBackArrow = document.querySelector('li[data-name="team_planner_view"] .main-menu--arrow-left-to-project') as HTMLElement|undefined;

        if (teamPlannerBackArrow) {
          teamPlannerBackArrow.click();
        }
      },
    },
  ];
}

export function navigateToTeamPlannerStep():OnboardingStep {
  return {
    'next .team-planner-view-menu-item': I18n.t('js.onboarding.steps.team_planner.overview'),
    showSkip: false,
    nextButton: { text: I18n.t('js.onboarding.buttons.next') },
    onNext() {
      jQuery('.team-planner-view-menu-item ~ .toggler')[0].click();

      waitForElement(
        '.op-submenu--item-action',
        '#main-menu',
        (match) => match.click(),
        (match) => !!match.textContent?.includes('Team planner'),
      );
    },
  };
}
