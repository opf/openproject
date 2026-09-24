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

import { NgModule } from '@angular/core';
import { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';
import {
  WorkPackageAction,
} from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';

const TIME_AND_COST_ACTION_KEYS = ['log_time', 'start_timer', 'stop_timer', 'log_costs'];

const allocateResourceAction:WorkPackageAction = {
  key: 'allocate_resource',
  icon: 'icon-user-plus',
  link: 'allocateResource',
  turboRequest: true,
  indexBy(actions:WorkPackageAction[]) {
    const index = actions.reduce(
      (last, action, i) => (TIME_AND_COST_ACTION_KEYS.includes(action.key) ? i : last),
      -1,
    );
    return index !== -1 ? index + 1 : actions.length;
  },
};

export function initializeResourceManagementPlugin() {
  void window.OpenProject.getPluginContext().then((pluginContext:OpenProjectPluginContext) => {
    pluginContext.hooks.workPackageSingleContextMenu(():WorkPackageAction => allocateResourceAction);

    pluginContext.hooks.workPackageTableContextMenu(():WorkPackageAction => ({
      ...allocateResourceAction,
      text: I18n.t('js.button_allocate_resource'),
    }));
  });
}

@NgModule({})
export class PluginModule {
  constructor() {
    initializeResourceManagementPlugin();
  }
}
