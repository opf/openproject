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

import { ApplicationController } from 'stimulus-use';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

export default class extends ApplicationController {
  static services:ServiceKey[] = ['turboRequests', 'pathHelperService'];

  declare services:Promise<PickedServices<'turboRequests'|'pathHelperService'>>;

  initialize() {
    super.initialize();
    useAngularServices(this);
  }

  async updateTimezoneText() {
    const data = new FormData(this.element as HTMLFormElement);
    const urlSearchParams = new URLSearchParams();
    let key:string;

    ['start_date', 'start_time_hour'].forEach((name) => {
      key = `meeting[${name}]`;
      urlSearchParams.append(key, data.get(key) as string);
    });

    const { turboRequests, pathHelperService } = await this.services;
    void turboRequests
      .request(
        `${pathHelperService.staticBase}/meetings/fetch_timezone?${urlSearchParams.toString()}`,
        {
          headers: {
            Accept: 'text/vnd.turbo-stream.html',
          },
        },
      );
  }
}
