// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.

import { Injector, NgModule } from '@angular/core';
import { OpenProjectPluginContext } from 'core-app/modules/plugins/plugin-context';
import { CostsByTypeDisplayField } from './wp-display/costs-by-type-display-field.module';
import { CurrencyDisplayField } from './wp-display/currency-display-field.module';

export function initializeCostsPlugin(injector:Injector) {
  window.OpenProject.getPluginContext().then((pluginContext:OpenProjectPluginContext) => {
    const displayFieldService = pluginContext.services.displayField;
    displayFieldService.addFieldType(CostsByTypeDisplayField, 'costs', ['costsByType']);
    displayFieldService.addFieldType(CurrencyDisplayField, 'currency', ['laborCosts', 'materialCosts', 'overallCosts']);

    pluginContext.hooks.workPackageSingleContextMenu(function (params:any) {
      return {
        key: 'log_costs',
        icon: 'icon-projects',
        indexBy: function (actions:any) {
          const index = _.findIndex(actions, { key: 'log_time' });
          return index !== -1 ? index + 1 : actions.length;
        },
        resource: 'workPackage',
        link: 'logCosts'
      };
    });

    pluginContext.hooks.workPackageTableContextMenu(function (params:any) {
      return {
        key: 'log_costs',
        icon: 'icon-projects',
        link: 'logCosts',
        indexBy: function (actions:any) {
          const index = _.findIndex(actions, { link: 'logTime' });
          return index !== -1 ? index + 1 : actions.length;
        },
        text: I18n.t('js.button_log_costs'),
      };
    });
  });
}


@NgModule({
  providers: [
  ],
})
export class PluginModule {
  constructor(injector:Injector) {
    initializeCostsPlugin(injector);
  }
}



