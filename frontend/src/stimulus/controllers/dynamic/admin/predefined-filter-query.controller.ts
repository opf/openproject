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

import { ApplicationInitStatus } from '@angular/core';
import { Controller } from '@hotwired/stimulus';
import { isEqual } from 'lodash-es';
import type { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

export default class PredefinedFilterQueryController extends Controller {
  static services:ServiceKey[] = ['externalQueryConfiguration', 'notifications', 'turboRequests'];
  static targets = ['input', 'submit'];
  static values = { summaryUrl: String };

  declare readonly inputTarget:HTMLInputElement;
  declare readonly submitTarget:HTMLButtonElement;
  declare readonly summaryUrlValue:string;
  declare services:Promise<PickedServices<'externalQueryConfiguration'|'notifications'|'turboRequests'>>;
  declare pluginContext:Promise<OpenProjectPluginContext>;

  private savedQuery:string|undefined;

  initialize() {
    useAngularServices(this);
  }

  async edit():Promise<void> {
    const [{ externalQueryConfiguration, notifications, turboRequests }, { injector }] = await Promise.all([this.services, this.pluginContext]);

    try {
      await injector.get(ApplicationInitStatus).donePromise;
      if (!this.element.isConnected) return;

      externalQueryConfiguration.show({
        currentQuery: this.inputTarget.value,
        urlParams: true,
        includeInitialQuery: true,
        callback: (queryProps:unknown, initialQuery?:string) => {
          if (!this.element.isConnected || typeof queryProps !== 'string' || initialQuery === undefined) return;
          if (this.sameQuery(queryProps, initialQuery)) return;

          if (this.submitTarget.disabled) this.savedQuery = initialQuery;

          this.inputTarget.value = queryProps;
          this.submitTarget.disabled = this.savedQuery !== undefined && this.sameQuery(queryProps, this.savedQuery);
          void turboRequests.request(this.summaryUrlValue, {
            method: 'POST',
            headers: { Accept: 'text/vnd.turbo-stream.html' },
            body: new URLSearchParams({ query_props: queryProps }),
          }, false, this.summaryUrlValue).catch(() => undefined);
        },
      });
    } catch (error) {
      notifications.addError(error instanceof Error ? error.message : String(error));
    }
  }

  private sameQuery(left:string, right:string):boolean {
    return isEqual(JSON.parse(left) as unknown, JSON.parse(right) as unknown);
  }
}
