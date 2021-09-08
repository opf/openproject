import { waitForElement } from 'core-app/core/setup/globals/onboarding/helpers';
import { OnboardingStep } from 'core-app/core/setup/globals/onboarding/onboarding_tour';

export function boardTourSteps():OnboardingStep[] {
  return [
    {
      'next .board-view-menu-item': I18n.t('js.onboarding.steps.boards.overview'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        jQuery('.board-view-menu-item ~ .toggler')[0].click();
        waitForElement('.boards--menu-items', '#main-menu', () => {
          jQuery(".main-menu--children-sub-item:contains('Kanban')")[0].click();
        });
      },
    },
    {
      'next [data-qa-selector="op-board-list"]': I18n.t('js.onboarding.steps.boards.lists'),
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
      'next [data-qa-selector="op-board-list--card-dropdown-add-button"]': I18n.t('js.onboarding.steps.boards.add'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      condition: () => document.getElementsByClassName('op-board-list--add-button').length !== 0,
    },
    {
      'next .boards-list--container': I18n.t('js.onboarding.steps.boards.drag'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      containerClass: '-dark -hidden-arrow',
      onNext() {
        const backArrows = Array.from(document.getElementsByClassName('main-menu--arrow-left-to-project'));
        const boardsBackArrow = backArrows.find((backArrow) => (backArrow.nextElementSibling as HTMLElement).innerText === 'Boards') as HTMLElement;

        if (boardsBackArrow) {
          boardsBackArrow.click();
        }
      },
    },
  ];
}
