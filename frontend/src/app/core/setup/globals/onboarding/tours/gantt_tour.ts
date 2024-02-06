import { OnboardingStep } from 'core-app/core/setup/globals/onboarding/onboarding_tour';

export function ganttOnboardingTourSteps():OnboardingStep[] {
  return [
    {
      'next .work-packages-tabletimeline--timeline-side': I18n.t('js.onboarding.steps.wp.timeline'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      containerClass: '-dark -hidden-arrow',
    },
    {
      'next [data-tour-selector="main-menu--arrow-left_gantt"]': I18n.t('js.onboarding.steps.sidebar_arrow'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        jQuery('[data-tour-selector="main-menu--arrow-left_gantt"]')[0].click();
      },
    },
  ];
}
