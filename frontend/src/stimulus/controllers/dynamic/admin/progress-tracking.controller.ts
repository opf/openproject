/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';

export default class ProgressTrackingController extends Controller {
  static values = {
    initialMode: String,
  };

  static targets = [
    'progressCalculationModeRadioGroup',
    'warningText',
    'warningToast',
    'statusClosedRadioGroup',
  ];

  declare readonly initialModeValue:string;

  declare readonly progressCalculationModeRadioGroupTarget:HTMLElement;
  declare readonly warningTextTarget:HTMLElement;
  declare readonly warningToastTarget:HTMLElement;
  declare readonly statusClosedRadioGroupTarget:HTMLElement;

  connect() {
    this.updateEnabledOptions();
  }

  updateEnabledOptions() {
    this.updateWarning();
    this.updateStatusClosedDisabledState();
  }

  updateWarning() {
    const warningMessageHtml = this.getWarningMessageHtml();
    if (warningMessageHtml) {
      this.warningTextTarget.innerHTML = warningMessageHtml;
      this.warningToastTarget.hidden = false;
    } else {
      this.warningToastTarget.hidden = true;
    }
  }

  updateStatusClosedDisabledState() {
    if (this.getSelectedMode() === 'status') {
      this.statusClosedRadioGroupTarget.setAttribute('disabled', 'true');
      this.statusClosedRadioGroupTarget.querySelectorAll('input').forEach((input) => {
        input.disabled = true;
      });
    } else {
      this.statusClosedRadioGroupTarget.removeAttribute('disabled');
      this.statusClosedRadioGroupTarget.querySelectorAll('input').forEach((input) => {
        input.disabled = false;
      });
    }
  }

  getSelectedMode() {
    const checkedRadio = this.progressCalculationModeRadioGroupTarget.querySelector('input:checked') as HTMLInputElement;
    return checkedRadio?.value || '';
  }

  getWarningMessageHtml():string {
    const selectedMode = this.getSelectedMode();
    if (selectedMode === this.initialModeValue || !selectedMode) {
      return '';
    }

    return I18n.t(
      `js.admin.work_packages_settings.warning_progress_calculation_mode_change_from_${this.initialModeValue}_to_${selectedMode}_html`,
    );
  }
}
