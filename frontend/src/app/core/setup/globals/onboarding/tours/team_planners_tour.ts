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

import { waitForElement } from 'core-app/core/setup/globals/onboarding/helpers';
import { OnboardingStep } from 'core-app/core/setup/globals/onboarding/onboarding_tour';

export function teamPlannerTourSteps():OnboardingStep[] {
  return [
    {
      'next [data-tour-selector="op-team-planner--calendar-pane"]': I18n.t('js.onboarding.steps.team_planner.calendar'),
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
      'next [data-tour-selector="tp-assignee-add-button"]': I18n.t('js.onboarding.steps.team_planner.add_assignee'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
    },
    {
      'next [data-tour-selector="op-team-planner--add-existing-toggle"]': I18n.t('js.onboarding.steps.team_planner.add_existing'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
    },
    {
      'next [data-tour-selector="op-wp-single-card"]': I18n.t('js.onboarding.steps.team_planner.card'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        const teamPlannerBackArrow = document.querySelector('li[data-name="team_planner_view"] .main-menu--arrow-left-to-project') as HTMLElement|undefined;

        if (teamPlannerBackArrow) {
          teamPlannerBackArrow.click();
        }
      },
    },
  ];
}

export function navigateToTeamPlannerStep():OnboardingStep {
  return {
    'next .team-planner-view-menu-item': I18n.t('js.onboarding.steps.team_planner.overview'),
    showSkip: false,
    nextButton: { text: I18n.t('js.onboarding.buttons.next') },
    onNext() {
      document.querySelector<HTMLElement>('.team-planner-view-menu-item ~ .toggler')?.click();

      waitForElement(
        '.op-submenu--item-action',
        '#main-menu',
        (match) => match.click(),
        (match) => !!match.textContent?.includes('Team planner'),
      );
    },
  };
}
