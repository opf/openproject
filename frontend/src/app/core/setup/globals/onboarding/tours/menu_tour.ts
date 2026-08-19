import { OnboardingStep } from 'core-app/core/setup/globals/onboarding/onboarding_tour';

export function menuTourSteps():OnboardingStep[] {
  return [
    {
      'next .members-menu-item': I18n.t('js.onboarding.steps.members'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      condition: () => document.getElementsByClassName('members-menu-item').length !== 0,
    },
    {
      'next .wiki-menu--main-item': I18n.t('js.onboarding.steps.wiki'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      condition: () => document.getElementsByClassName('wiki-menu--main-item').length !== 0,
    },
    {
      'next #op-app-header--quick-add-menu-button': I18n.t('js.onboarding.steps.quick_add_button'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      condition: () => document.getElementById('op-app-header--quick-add-menu-button') !== undefined,
    },
    {
      'next #op-app-header--help-menu-button': I18n.t('js.onboarding.steps.help_menu'),
      shape: 'circle',
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.got_it') },
    },
  ];
}
