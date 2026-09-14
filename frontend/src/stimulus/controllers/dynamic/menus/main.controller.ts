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
import { MainMenuNavigationService } from 'core-app/core/main-menu/main-menu-navigation.service';
import type { OpenProjectPluginContext } from 'core-app/features/plugins/plugin-context';
import { useAngularServices } from 'core-stimulus/mixins/use-angular-services';

export default class MainMenuController extends Controller {
  static targets = [
    'sidebar',
    'root',
    'item',
  ];

  declare readonly sidebarTarget:HTMLElement;
  declare readonly rootTarget:HTMLElement;
  declare readonly itemTargets:HTMLElement[];

  declare pluginContext:Promise<OpenProjectPluginContext>;

  initialize() {
    // Must come first: markActive() below already reads this.pluginContext.
    useAngularServices(this);

    if (this.rootTarget.classList.contains('closed')) {
      this.sidebarTarget.classList.add('-hidden');
    }

    const active = this.getActiveMenuName();
    if (active) {
      void this.markActive(active);
    }
  }

  descend(event:MouseEvent) {
    const target = event.target as HTMLElement;
    this.sidebarTarget.classList.add('-hidden');
    const targetLi = target.closest('li') as HTMLElement;

    this.toggleMenuState(this.rootTarget);
    this.toggleMenuState(targetLi);

    targetLi.querySelector<HTMLElement>('li > a, .tree-menu--title')?.focus();

    targetLi.querySelector<HTMLElement>('.main-menu--arrow-left-to-project')?.focus();
    void this.markActive(targetLi.dataset.name!);
  }

  ascend(event:MouseEvent) {
    event.preventDefault();
    const target = event.target as HTMLElement;
    const parent = target.closest('li') as HTMLElement;

    this.toggleMenuState(parent);
    this.toggleMenuState(this.rootTarget);

    parent.querySelector<HTMLElement>('.toggler')?.focus();

    this.sidebarTarget.classList.remove('-hidden');
  }

  private getActiveMenuName():string|undefined {
    const activeItem = this.itemTargets.find((el) => el.classList.contains('open'));
    const activeRoot = this.rootTarget.querySelector('li');
    return (activeItem || activeRoot)?.dataset.name;
  }

  private async markActive(active:string) {
    const { injector } = await this.pluginContext;
    injector.get(MainMenuNavigationService).navigationEvents$.next(active);
  }

  private toggleMenuState(item:HTMLElement) {
    item.classList.toggle('closed');
    item.classList.toggle('open');
  }
}
