/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
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

import { Controller } from '@hotwired/stimulus';

export default class ManagedProjectFoldersFormController extends Controller {
  static targets = [
    'automaticallyManagedSwitch',
    'applicationPasswordInput',
  ];

  static values = {
    isAutomaticallyManaged: Boolean,
  };

  declare readonly automaticallyManagedSwitchTarget:HTMLElement;
  declare readonly applicationPasswordInputTarget:HTMLElement;
  declare readonly hasApplicationPasswordInputTarget:boolean;

  declare isAutomaticallyManagedValue:boolean;

  spotSwitchComponent!:HTMLElement;
  boundUpdateDisplay!:(evt:InputEvent) => (void | boolean);

  connect():void {
    // On first load if isAutomaticallyManaged is true, show the applicationPasswordInput
    this.toggleApplicationPasswordDisplay(this.isAutomaticallyManagedValue);

    // Bind the spotSwitchComponent change event to updateDisplay
    // The boundUpdateDisplay reference is needed to remove the same event listener in disconnect()
    this.boundUpdateDisplay = this.updateDisplay.bind(this);
    this.spotSwitchComponent = this.findSpotSwitchComponent();
    this.spotSwitchComponent.addEventListener('change', this.boundUpdateDisplay);
  }

  disconnect():void {
    this.spotSwitchComponent.removeEventListener('change', this.boundUpdateDisplay);
  }

  updateDisplay(evt:InputEvent):(void | boolean) {
    // when isAutomaticallyManaged is false, the applicationPasswordInput would have been hidden
    if (!this.hasApplicationPasswordInputTarget) {
      return;
    }

    this.toggleApplicationPasswordDisplay((evt.target as HTMLInputElement).checked);
  }

  toggleApplicationPasswordDisplay(displayApplicationPasswordInput:boolean):void {
    if (displayApplicationPasswordInput) {
      this.applicationPasswordInputTarget.style.display = 'flex';
    } else {
      this.applicationPasswordInputTarget.style.display = 'none';
    }
  }

  findSpotSwitchComponent():HTMLElement {
    // spot-switch is an Angular template with an input checkbox field as the event target
    return this.automaticallyManagedSwitchTarget.querySelector('spot-switch') as HTMLElement;
  }
}
