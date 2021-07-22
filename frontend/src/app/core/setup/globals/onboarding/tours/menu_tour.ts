export function menuTourSteps() {
  return [
    {
      'next .members-menu-item': I18n.t('js.onboarding.steps.members'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      condition: () => {
        return document.getElementsByClassName('members-menu-item').length !== 0;
      },
    },
    {
      'next .wiki-menu--main-item': I18n.t('js.onboarding.steps.wiki'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      condition: () => {
        return document.getElementsByClassName('wiki-menu--main-item').length !== 0;
      },
    },
    {
      'next .op-quick-add-menu': I18n.t('js.onboarding.steps.quick_add_button'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      condition: () => {
        return document.getElementsByClassName('op-quick-add-menu--icon').length !== 0;
      },
    },
    {
      'next .op-app-help': I18n.t('js.onboarding.steps.help_menu'),
      shape: 'circle',
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.got_it') },
    },
  ];
}
