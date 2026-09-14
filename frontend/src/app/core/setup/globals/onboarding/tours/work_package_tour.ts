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

export function wpOnboardingTourSteps():OnboardingStep[] {
  return [
    {
      'next .add-work-package': I18n.t('js.onboarding.steps.wp.create_button'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      shape: 'circle',
      timeout: () => new Promise((resolve) => {
        // We are waiting here for the badge to appear,
        // because it's the last that appears and it shifts the WP create button to the left.
        // Thus it is important that the tour rendering starts after the badge is visible
        waitForElement('#work-packages-filter-toggle-button .badge', '#content', () => {
          resolve(undefined);
        });
      })
    },
    {
      'next .wp-table--row': I18n.t('js.onboarding.steps.wp.list'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        const firstId = document.querySelectorAll('.inline-edit--display-field.id a ')[0].innerHTML;
        window.location.href = `${window.location.origin}/projects/demo-project/work_packages/${firstId}/activity`;
      },
    }
  ];
}
