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

import { ApplicationController } from 'stimulus-use';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

export default class PermissionsPreviewController extends ApplicationController {
  static services:ServiceKey[] = ['turboRequests'];

  static targets = ['select', 'trigger'];

  static values = { paths: { type: Object, default: {} } };

  declare readonly selectTarget:HTMLSelectElement;

  declare readonly hasSelectTarget:boolean;

  declare readonly triggerTarget:HTMLElement;

  declare readonly hasTriggerTarget:boolean;

  declare readonly pathsValue:Record<string, string>;

  declare services:Promise<PickedServices<'turboRequests'>>;

  private trackedRoleId?:string;

  initialize() {
    super.initialize();
    useAngularServices(this);
  }

  // Widgets without a native select, such as the Angular autocompleter, report their
  // selection through the hidden field they keep in sync.
  track(event:Event) {
    this.trackedRoleId = (event.target as HTMLInputElement).value;

    if (this.hasTriggerTarget) {
      this.triggerTarget.hidden = !this.selectedPath();
    }
  }

  async open() {
    const path = this.selectedPath();
    if (!path) { return; }

    const { turboRequests } = await this.services;
    void turboRequests.request(path, { headers: { Accept: 'text/vnd.turbo-stream.html' } });
  }

  private selectedPath():string|undefined {
    if (this.hasSelectTarget) {
      return this.selectTarget.selectedOptions[0]?.dataset.permissionsDialogPath;
    }

    return this.trackedRoleId ? this.pathsValue[this.trackedRoleId] : undefined;
  }
}
