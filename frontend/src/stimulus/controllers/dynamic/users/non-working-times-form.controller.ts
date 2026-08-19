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

export default class NonWorkingTimesFormController extends Controller {
  static targets = [
    'workingDaysInput',
  ];

  static values = {
    previewUrl: String,
  };

  declare readonly workingDaysInputTarget:HTMLInputElement;
  declare readonly hasWorkingDaysInputTarget:boolean;
  declare readonly previewUrlValue:string;

  previewWorkingDays() {
    const startDate = (this.element.querySelector<HTMLInputElement>('#user_non_working_time_start_date')?.value);
    const endDate = (this.element.querySelector<HTMLInputElement>('#user_non_working_time_end_date')?.value);

    if (!startDate || !endDate) return;

    void fetch(`${this.previewUrlValue}?start_date=${startDate}&end_date=${endDate}`, {
      headers: { Accept: 'application/json' },
    })
      .then((r) => r.json() as Promise<{ working_days:number }>)
      .then(({ working_days }) => {
        if (this.hasWorkingDaysInputTarget) {
          this.workingDaysInputTarget.value = String(working_days);
        }
      });
  }
}
