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
import { useMeta } from 'stimulus-use';
import { durationStringToSeconds, formattedHour } from 'core-stimulus/helpers/chronic-duration-helper';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

export default class TimeEntryController extends Controller {
  static services:ServiceKey[] = ['turboRequests', 'pathHelperService'];

  static targets = ['startTimeInput', 'endTimeInput', 'hoursInput', 'hoursHiddenInput', 'form'];

  declare readonly formTarget:HTMLFormElement;
  declare readonly startTimeInputTarget:HTMLInputElement;
  declare readonly hasStartTimeInputTarget:boolean;
  declare readonly endTimeInputTarget:HTMLInputElement;
  declare readonly hasEndTimeInputTarget:boolean;
  declare readonly hoursInputTarget:HTMLInputElement;
  declare readonly hoursHiddenInputTarget:HTMLInputElement;
  declare oldWorkPackageId:string;

  static metaNames = ['csrf-token'];

  declare readonly csrfToken:string;

  declare services:Promise<PickedServices<'turboRequests'|'pathHelperService'>>;

  initialize() {
    useAngularServices(this);
  }

  connect() {
    useMeta(this, { suffix: false });

    const workPackageAutocompleter = document.querySelector('opce-autocompleter[data-input-name*="time_entry[entity_id]"]');
    if (workPackageAutocompleter) {
      this.oldWorkPackageId = (workPackageAutocompleter as HTMLElement).dataset.inputValue ?? '';
    }
  }

  async userChanged(event:InputEvent) {
    const userId = (event.currentTarget as HTMLInputElement).value;
    const { turboRequests, pathHelperService } = await this.services;
    void turboRequests.request(
      pathHelperService.timeEntriesUserTimezoneCaption(userId),
      { method: 'GET' },
    );
  }

  async entityChanged(event:InputEvent) {
    const target = event.currentTarget as HTMLInputElement;
    const newValue = target.value;

    if (this.oldWorkPackageId !== newValue) {
      this.oldWorkPackageId = newValue;

      const url = this.formTarget.dataset.refreshFormUrl!;
      const formData = new FormData(this.formTarget);
      formData.delete('_method'); // remove the override method as this will submit to the wrong action
      const { turboRequests } = await this.services;
      void turboRequests.request(url, {
        method: 'post',
        body: formData,
        headers: {
          'X-CSRF-Token': this.csrfToken,
        },
      });
    }
  }

  timeInputChanged(event:InputEvent) {
    this.datesChanged(event.currentTarget as HTMLInputElement);
  }

  datesChanged(initiatedBy:HTMLInputElement) {
    if (!this.hasStartTimeInputTarget || !this.hasEndTimeInputTarget) {
      return;
    }

    // The time entry input fields are currently not valid, so we do not need to calculate anything.
    // A time entry input field is invalid when it is only partially filled out.
    if (!this.startTimeInputTarget.checkValidity() || !this.endTimeInputTarget.checkValidity()) {
      return;
    }

    // when we have reset one of the input fields for start- or end-time, we want to unset both fields
    if ((initiatedBy === this.startTimeInputTarget && this.startTimeInputTarget.value === '') || (initiatedBy === this.endTimeInputTarget && this.endTimeInputTarget.value === '')) {
      this.startTimeInputTarget.value = '';
      this.endTimeInputTarget.value = '';
      this.toggleEndTimePlusCaption(0, 0);
      return;
    }

    const startTimeParts = this.startTimeInputTarget.value.split(':');
    const endTimeParts = this.endTimeInputTarget.value.split(':');

    const startTimeInMinutes = parseInt(startTimeParts[0], 10) * 60 + parseInt(startTimeParts[1], 10);
    const endTimeInMinutes = parseInt(endTimeParts[0], 10) * 60 + parseInt(endTimeParts[1], 10);
    let hoursInMinutes = Math.round(durationStringToSeconds(this.hoursInputTarget.value) / 60);

    // We calculate the hours field if:
    //  - We have start & end time and no hours
    //  - We have start & end time and we have triggered the change from the end time field
    if (startTimeInMinutes && endTimeInMinutes && (hoursInMinutes === 0 || initiatedBy === this.endTimeInputTarget)) {
      let exisitingDayGap = 0;

      // when we already had hours set, and they were above 24 hours, we would most likely want to stay on that end date
      if (hoursInMinutes >= 24 * 60) {
        exisitingDayGap = Math.floor(hoursInMinutes / (24 * 60)) * (60 * 24);
      }

      hoursInMinutes = endTimeInMinutes - startTimeInMinutes;
      if (hoursInMinutes <= 0) {
        hoursInMinutes += 24 * 60;
      }

      hoursInMinutes += exisitingDayGap;

      this.hoursInputTarget.value = formattedHour(hoursInMinutes * 60);
      this.setHoursPrecise(hoursInMinutes / 60);
    } else if (startTimeInMinutes && hoursInMinutes) {
      const newEndTime = (startTimeInMinutes + hoursInMinutes) % (24 * 60);

      this.endTimeInputTarget.value = [
        Math.floor(newEndTime / 60).toString().padStart(2, '0'),
        Math.round(newEndTime % 60).toString().padStart(2, '0'),
      ].join(':');
    } else if (endTimeInMinutes && hoursInMinutes) {
      const newStartTime = (endTimeInMinutes - hoursInMinutes) % (24 * 60);

      this.startTimeInputTarget.value = [
        Math.floor(newStartTime / 60).toString().padStart(2, '0'),
        Math.round(newStartTime % 60).toString().padStart(2, '0'),
      ].join(':');
    }

    this.toggleEndTimePlusCaption(startTimeInMinutes, hoursInMinutes);
  }

  hoursChanged() {
    // Parse input through our chronic duration parser and then reformat as hours that can be nicely parsed on the
    // backend
    const duration = durationStringToSeconds(this.hoursInputTarget.value);
    this.hoursInputTarget.value = formattedHour(duration);
    this.setHoursPrecise(duration / 3600);

    if (duration !== 0) {
      this.datesChanged(this.hoursInputTarget);
    }
  }

  private setHoursPrecise(hours:number) {
    this.hoursHiddenInputTarget.value = String(hours);
  }

  hoursKeyEnterPress(event:KeyboardEvent) {
    if (event.currentTarget instanceof HTMLInputElement) {
      event.currentTarget.blur();
    }
  }

  toggleEndTimePlusCaption(startTimeInMinutes:number, hoursInMinutes:number) {
    const formControl = this.endTimeInputTarget.closest('.FormControl')!;
    formControl
      .querySelectorAll('.FormControl-caption')
      .forEach((caption) => { caption.remove(); });

    if (startTimeInMinutes + hoursInMinutes >= 24 * 60) {
      const diffInDays = Math.floor((startTimeInMinutes + hoursInMinutes) / (60 * 24));
      const span = document.createElement('span');
      span.className = 'FormControl-caption';
      span.innerText = `+${diffInDays === 1 ? I18n.t('js.units.day.one') : I18n.t('js.units.day.other', { count: diffInDays })}`;
      formControl.append(span);
    }
  }
}
