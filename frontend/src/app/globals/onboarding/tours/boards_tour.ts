import { waitForElement } from "core-app/globals/onboarding/helpers";

export function boardTourSteps() {
  return [
    {
      'next .board-view-menu-item': I18n.t('js.onboarding.steps.boards.overview'),
      'showSkip': false,
      'nextButton': { text: I18n.t('js.onboarding.buttons.next') },
      onNext: function () {
        jQuery('.board-view-menu-item ~ .toggler')[0].click();
        waitForElement('.boards--menu-items', '#main-menu', function () {
          jQuery(".main-menu--children-sub-item:contains('Kanban')")[0].click();
        });
      }
    },
    {
      'next .board-list--container': I18n.t('js.onboarding.steps.boards.lists'),
      'showSkip': false,
      'nextButton': { text: I18n.t('js.onboarding.buttons.next') },
      'containerClass': '-dark -hidden-arrow',
      'timeout': function () {
        return new Promise(function (resolve) {
          waitForElement('.wp-card', '#content', function () {
            resolve(undefined);
          });
        });
      }
    },
    {
      'next .board-list--add-button': I18n.t('js.onboarding.steps.boards.add'),
      'showSkip': false,
      'nextButton': { text: I18n.t('js.onboarding.buttons.next') },
    },
    {
      'next .boards-list--container': I18n.t('js.onboarding.steps.boards.drag'),
      'showSkip': false,
      'nextButton': { text: I18n.t('js.onboarding.buttons.next') },
      'containerClass': '-dark -hidden-arrow',
      onNext: function () {
        const backArrows = Array.from(document.getElementsByClassName('main-menu--arrow-left-to-project'));
        const boardsBackArrow = backArrows.find((backArrow) => (backArrow.nextElementSibling as HTMLElement).innerText === 'Boards') as HTMLElement;

        boardsBackArrow && boardsBackArrow.click();
      }
    }
  ];
}
