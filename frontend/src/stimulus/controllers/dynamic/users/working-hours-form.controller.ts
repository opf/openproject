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
import { durationStringToSeconds, formattedHour } from 'core-stimulus/helpers/chronic-duration-helper';

export default class WorkingHoursFormController extends Controller {
  static targets = [
    'sameHoursSection',
    'individualSection',
    'sharedHoursInput',
    'dayCheckbox',
    'dayHoursInput',
    'totalWorkHoursDisplay',
    'availabilityFactorInput',
    'totalAvailableHoursDisplay',
  ];

  declare readonly sameHoursSectionTarget:HTMLElement;
  declare readonly individualSectionTarget:HTMLElement;
  declare readonly sharedHoursInputTarget:HTMLInputElement;
  declare readonly dayCheckboxTargets:HTMLInputElement[];
  declare readonly dayHoursInputTargets:HTMLInputElement[];
  declare readonly totalWorkHoursDisplayTarget:HTMLInputElement;
  declare readonly availabilityFactorInputTarget:HTMLInputElement;
  declare readonly totalAvailableHoursDisplayTarget:HTMLInputElement;

  private hoursModeValue:'same'|'individual' = 'same';

  connect() {
    this.detectHoursMode();
    this.hideDisabledDayHours();
    this.recalculate();
  }

  hoursModeChanged(event:Event) {
    this.hoursModeValue = (event.target as HTMLInputElement).value as 'same' | 'individual';
    this.updateDisplayMode();
    if (this.hoursModeValue === 'same') {
      this.syncSameHoursToAllDays();
    }
    this.recalculate();
  }

  dayToggled(event:Event) {
    const checkbox = event.target as HTMLInputElement;
    const day = checkbox.dataset.day!;
    const hoursInput = this.dayHoursInputForDay(day);

    if (hoursInput) {
      hoursInput.disabled = !checkbox.checked;
      this.toggleDayHoursWrapperVisibility(day, checkbox.checked);
    }

    if (this.hoursModeValue === 'same') {
      this.syncSameHoursToAllDays();
    }
    this.recalculate();
  }

  hoursChanged() {
    if (this.hoursModeValue === 'same') {
      this.syncSameHoursToAllDays();
    }
    this.recalculate();
  }


  // Triggered on blur: parse the entered duration string and reformat as a plain decimal hours value.
  // This lets users type "4:30", "4h30min", "4,5", etc. — same logic as the time entry form.
  hoursFormatted(event:Event) {
    const input = event.target as HTMLInputElement;
    const seconds = durationStringToSeconds(input.value);
    input.value = formattedHour(seconds);

    if (this.hoursModeValue === 'same') {
      this.syncSameHoursToAllDays();
    }

    this.recalculate();
  }

  availabilityChanged() {
    this.recalculate();
  }

  private detectHoursMode() {
    const checked = this.element.querySelector<HTMLInputElement>('input[name="user_working_hours[hours_mode]"]:checked');
    if (checked) {
      this.hoursModeValue = checked.value as 'same' | 'individual';
    }

    this.updateDisplayMode();
  }

  private hideDisabledDayHours() {
    this.dayCheckboxTargets.forEach((checkbox) => {
      const day = checkbox.dataset.day!;
      this.toggleDayHoursWrapperVisibility(day, checkbox.checked);
    });
  }

  private updateDisplayMode() {
    const isSame = this.hoursModeValue === 'same';
    this.sameHoursSectionTarget.classList.toggle('d-none', !isSame);
    this.individualSectionTarget.classList.toggle('d-none', isSame);
  }

  private syncSameHoursToAllDays() {
    const seconds = durationStringToSeconds(this.sharedHoursInputTarget.value);

    this.dayHoursInputTargets.forEach((input) => {
      const checkbox = this.dayCheckboxForDay(input.dataset.day!);
      if (checkbox?.checked) {
        input.value = formattedHour(seconds);
      }
    });
  }

  private recalculate() {
    let totalHours = 0;

    if (this.hoursModeValue === 'same') {
      const seconds = durationStringToSeconds(this.sharedHoursInputTarget.value);
      const checkedCount = this.dayCheckboxTargets.filter((cb) => cb.checked).length;
      totalHours = seconds * checkedCount;
    } else {
      this.dayHoursInputTargets.forEach((input) => {
        const checkbox = this.dayCheckboxForDay(input.dataset.day!);
        if (checkbox?.checked) {
          totalHours += durationStringToSeconds(input.value);
        }
      });
    }

    this.totalWorkHoursDisplayTarget.value = formattedHour(totalHours, false);

    const factor = parseFloat(this.availabilityFactorInputTarget.value);
    const available = totalHours * (isNaN(factor) ? 100 : factor) / 100;
    this.totalAvailableHoursDisplayTarget.value = formattedHour(available, false);
  }

  private dayHoursInputForDay(day:string):HTMLInputElement|undefined {
    return this.dayHoursInputTargets.find((el) => el.dataset.day === day);
  }

  private toggleDayHoursWrapperVisibility(day:string, visible:boolean) {
    const input = this.dayHoursInputForDay(day);

    if (input) {
      const wrapper = input.closest<HTMLElement>('primer-text-field');
      if (wrapper) {
        wrapper.classList.toggle('d-none', !visible);
      }
    }
  }

  private dayCheckboxForDay(day:string):HTMLInputElement|undefined {
    return this.dayCheckboxTargets.find((el) => el.dataset.day === day);
  }
}
