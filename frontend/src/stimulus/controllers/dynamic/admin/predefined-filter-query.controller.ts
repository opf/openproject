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

export default class PredefinedFilterQueryController extends Controller<HTMLFormElement> {
  static services:ServiceKey[] = ['externalQueryConfiguration', 'notifications'];
  static targets = ['input'];

  declare readonly inputTarget:HTMLInputElement;
  declare services:Promise<PickedServices<'externalQueryConfiguration'|'notifications'>>;
  declare pluginContext:Promise<OpenProjectPluginContext>;

  initialize() {
    useAngularServices(this);
  }

  async edit():Promise<void> {
    const [{ externalQueryConfiguration, notifications }, { injector }] = await Promise.all([this.services, this.pluginContext]);

    try {
      await injector.get(ApplicationInitStatus).donePromise;
      if (!this.element.isConnected) return;

      externalQueryConfiguration.show({
        currentQuery: this.inputTarget.value,
        urlParams: true,
        includeInitialQuery: true,
        saveOnApply: true,
        callback: (queryProps:unknown, initialQuery?:string) => {
          if (!this.element.isConnected || typeof queryProps !== 'string' || initialQuery === undefined) return;
          if (this.sameQuery(queryProps, initialQuery)) return;

          this.inputTarget.value = queryProps;
          this.element.requestSubmit();
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
