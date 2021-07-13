export function menuTourSteps() {
  return [
    {
      'next .members-menu-item': I18n.t('js.onboarding.steps.members'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
    },
    {
      'next .wiki-menu--main-item': I18n.t('js.onboarding.steps.wiki'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
    },
    {
      'next .op-quick-add-menu': I18n.t('js.onboarding.steps.quick_add_button'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
    },
    {
      'next .op-app-help': I18n.t('js.onboarding.steps.help_menu'),
      shape: 'circle',
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.got_it') },
    },
  ];
}
