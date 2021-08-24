import { OnboardingStep } from 'core-app/core/setup/globals/onboarding/onboarding_tour';

export function prepareScrumBacklogsTourSteps():OnboardingStep[] {
  return [
    {
      'next .backlogs-menu-item': I18n.t('js.onboarding.steps.backlogs.overview'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      containerClass: '-dark -hidden-arrow',
      onNext() {
        jQuery('.backlogs-menu-item')[0].click();
      },
    },
  ];
}

export function scrumBacklogsTourSteps():OnboardingStep[] {
  return [
    {
      'next #content-wrapper': I18n.t('js.onboarding.steps.backlogs.sprints'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      containerClass: '-dark -hidden-arrow',
    },
    {
      event_type: 'next',
      selector: '#sprint_backlogs_container .backlog .menu-trigger',
      description: I18n.t('js.onboarding.steps.backlogs.task_board_arrow'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        jQuery('#sprint_backlogs_container .backlog .menu-trigger')[0].click();
      },
    },
    {
      event_type: 'next',
      selector: '#sprint_backlogs_container .backlog .menu .items',
      description: I18n.t('js.onboarding.steps.backlogs.task_board_select'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      containerClass: '-dark',
      onNext() {
        jQuery('#sprint_backlogs_container .backlog .show_task_board')[0].click();
      },
    },
  ];
}

export function scrumTaskBoardTourSteps():OnboardingStep[] {
  return [
    {
      'next #content-wrapper': I18n.t('js.onboarding.steps.backlogs.task_board'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      containerClass: '-dark -hidden-arrow',
      condition: () => document.getElementsByClassName('backlogs-menu-item').length !== 0,
    },
    {
      'next #main-menu-work-packages-wrapper': I18n.t('js.onboarding.steps.wp.toggler'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        jQuery('#main-menu-work-packages')[0].click();
      },
    },
  ];
}
