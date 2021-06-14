import { onboardingTourStorageKey } from "core-app/globals/onboarding/helpers";

export function scrumBacklogsTourSteps() {
  return [
    {
      'next #content-wrapper': I18n.t('js.onboarding.steps.backlogs.overview'),
      'showSkip': false,
      'nextButton': { text: I18n.t('js.onboarding.buttons.next') },
      'containerClass': '-dark -hidden-arrow'
    },
    {
      'event_type': 'next',
      'selector': '#sprint_backlogs_container .backlog .menu-trigger',
      'description': I18n.t('js.onboarding.steps.backlogs.task_board_arrow'),
      'showSkip': false,
      'nextButton': { text: I18n.t('js.onboarding.buttons.next') },
      onNext: function () {
        jQuery('#sprint_backlogs_container .backlog .menu-trigger')[0].click();
      }
    },
    {
      'event_type': 'next',
      'selector': '#sprint_backlogs_container .backlog .menu .items',
      'description': I18n.t('js.onboarding.steps.backlogs.task_board_select'),
      'showSkip': false,
      'nextButton': { text: I18n.t('js.onboarding.buttons.next') },
      'containerClass': '-dark',
      onNext: function () {
        jQuery('#sprint_backlogs_container .backlog .show_task_board')[0].click();
      }
    }
  ];
}

export function scrumTaskBoardTourSteps() {
  return [
    {
      'next #content-wrapper': I18n.t('js.onboarding.steps.backlogs.task_board'),
      'showSkip': false,
      'nextButton': { text: I18n.t('js.onboarding.buttons.next') },
      'containerClass': '-dark -hidden-arrow'
    },
    {
      'next #main-menu-work-packages-wrapper': I18n.t('js.onboarding.steps.wp.toggler'),
      'showSkip': false,
      'nextButton': { text: I18n.t('js.onboarding.buttons.next') },
      onNext: function () {
        jQuery('#main-menu-work-packages')[0].click();
      }
    },
  ];
}
