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
