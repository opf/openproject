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

import OpMeetingsFormController from 'core-stimulus/controllers/dynamic/meetings/form.controller';

export default class OpRecurringMeetingsFormController extends OpMeetingsFormController {
  static values = {
    persisted: Boolean,
  };

  declare persistedValue:boolean;

  async updateFrequencyText() {
    const data = new FormData(this.element as HTMLFormElement);
    const urlSearchParams = new URLSearchParams();
    [
      'start_date',
      'start_time_hour',
      'frequency',
      'interval',
      'monthly_day',
      'monthly_ordinal',
      'monthly_weekday',
      'time_zone',
      'end_after',
      'end_date',
      'iterations',
    ].forEach((name) => {
      const key = `meeting[${name}]`;
      urlSearchParams.append(key, data.get(key) as string);
    });

    const { turboRequests, pathHelperService } = await this.services;
    void turboRequests
      .request(
        `${pathHelperService.staticBase}/recurring_meetings/humanize_schedule?${urlSearchParams.toString()}`,
        {
          headers: {
            Accept: 'text/vnd.turbo-stream.html',
          },
        },
      );
  }

  async updateTimezoneText() {
    // We don't update the timezone text on editing recurring meetings
    if (this.persistedValue) {
      return;
    }

    await super.updateTimezoneText();
  }
}
