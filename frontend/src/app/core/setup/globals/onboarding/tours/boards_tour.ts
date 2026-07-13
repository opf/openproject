import {
  waitForElement,
} from 'core-app/core/setup/globals/onboarding/helpers';
import { OnboardingStep } from 'core-app/core/setup/globals/onboarding/onboarding_tour';

export function boardTourSteps():OnboardingStep[] {
  const listExplanation = 'kanban';

  return [
    {
      'next [data-tour-selector="op-board-list"]': I18n.t(`js.onboarding.steps.boards.lists_${listExplanation}`),
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
      'next [data-tour-selector="op-board-list--card-dropdown-add-button"]': I18n.t('js.onboarding.steps.boards.add'),
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
        document.querySelector<HTMLElement>('[data-tour-selector="main-menu--arrow-left_boards"]')?.click();
      },
    },
  ];
}

export function navigateToBoardStep():OnboardingStep {
  const boardName= 'Kanban';

  return {
    'next #boards-wrapper>.boards-menu-item': I18n.t('js.onboarding.steps.boards.overview'),
    showSkip: false,
    nextButton: { text: I18n.t('js.onboarding.buttons.next') },
    onNext() {
      document.querySelector<HTMLElement>('#boards-wrapper>.boards-menu-item ~ .toggler')?.click();
      waitForElement(
        '.op-submenu--item-action',
        '#main-menu',
        (match) => match.click(),
        (match) => !!match.textContent?.includes(boardName),
      );
    },
  };
}
