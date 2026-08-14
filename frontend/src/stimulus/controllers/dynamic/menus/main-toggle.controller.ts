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

import { Controller } from '@hotwired/stimulus';
import { MainMenuToggleService } from 'core-app/core/main-menu/main-menu-toggle.service';
import type { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';
import { useAngularServices } from 'core-stimulus/mixins/use-angular-services';

export default class MainToggleController extends Controller {
  declare pluginContext:Promise<OpenProjectPluginContext>;

  mainMenuService:MainMenuToggleService|undefined;

  initialize() {
    useAngularServices(this);
  }

  servicesConnected() {
    void this.connectMenuService();
  }

  disconnect() {
    this.mainMenuService = undefined;
  }

  toggleNavigation(e:Event) {
    this.mainMenuService?.toggleNavigation(e);
  }

  private async connectMenuService() {
    try {
      const { injector } = await this.pluginContext;
      this.mainMenuService = injector.get(MainMenuToggleService);
      this.mainMenuService.initializeMenu();
    } catch {
      // Keep swallowing injector failures, as the previous chain did — the
      // toggle then stays inert instead of erroring on every page.
    }
  }
}
