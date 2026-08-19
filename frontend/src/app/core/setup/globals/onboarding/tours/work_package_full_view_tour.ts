import { OnboardingStep } from 'core-app/core/setup/globals/onboarding/onboarding_tour';

export function wpFullViewOnboardingTourSteps():OnboardingStep[] {
  return [
    {
      'next .work-packages-full-view--split-left': I18n.t('js.onboarding.steps.wp.full_view'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      containerClass: '-dark -hidden-arrow',
      onNext() {
        document.querySelector<HTMLElement>('.main-menu--arrow-left-to-project')?.click();
      },
    },
    {
      'next #main-menu-gantt': I18n.t('js.onboarding.steps.wp.gantt_menu'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        document.querySelector<HTMLElement>('#main-menu-gantt')?.click();
      },
    },
    {
      containerClass: '-dark -hidden-arrow',
      onBeforeStart() {
        window.location.href = `${window.location.origin}/projects/demo-project/gantt`;
      },
    },
  ];
}
