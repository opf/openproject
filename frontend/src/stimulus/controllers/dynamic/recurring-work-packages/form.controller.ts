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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ApplicationController } from 'stimulus-use';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

export default class OpRecurringWorkPackagesFormController extends ApplicationController {
  static services:ServiceKey[] = ['turboRequests'];

  static values = {
    previewUrl: String,
  };

  declare services:Promise<PickedServices<'turboRequests'>>;
  declare previewUrlValue:string;

  initialize() {
    super.initialize();
    useAngularServices(this);
  }

  async updatePreview() {
    const data = new FormData(this.element as HTMLFormElement);
    const params = new URLSearchParams();
    data.forEach((value, key) => {
      if (key.startsWith('series[')) {
        params.append(key, value as string);
      }
    });

    const { turboRequests } = await this.services;
    await turboRequests
      .request(
        `${this.previewUrlValue}?${params.toString()}`,
        { headers: { Accept: 'text/vnd.turbo-stream.html' } },
        false,
        'recurring-work-packages-preview',
      )
      .catch((error:unknown) => {
        if (!(error instanceof DOMException && error.name === 'AbortError')) {
          throw error;
        }
      });
  }
}
