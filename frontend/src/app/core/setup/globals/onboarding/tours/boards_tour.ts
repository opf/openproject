//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
