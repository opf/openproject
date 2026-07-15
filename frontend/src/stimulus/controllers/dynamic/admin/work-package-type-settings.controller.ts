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

import { Controller } from '@hotwired/stimulus';

// Sub-types inherit their core settings (color, milestone, roadmap, default)
// from the parent, so those fields must be hidden and excluded from submission
// as soon as a parent is selected, and revealed again when it is cleared.
export default class WorkPackageTypeSettingsController extends Controller {
  static targets = ['coreSetting'];

  static values = {
    inherited: Boolean,
  };

  declare readonly inheritedValue:boolean;

  declare readonly coreSettingTargets:HTMLElement[];

  connect() {
    this.apply(this.inheritedValue);
  }

  toggle(event:Event) {
    this.apply((event.target as HTMLSelectElement).value !== '');
  }

  private apply(inherited:boolean) {
    this.coreSettingTargets.forEach((group) => {
      group.classList.toggle('d-none', inherited);
      group
        .querySelectorAll<HTMLInputElement>('input, select, textarea')
        .forEach((element) => { element.disabled = inherited; });
    });
  }
}
