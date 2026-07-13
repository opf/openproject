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

export default class WorkPackagesIdentifierController extends Controller {
  static values = {
    hasProblematicProjects: Boolean,
    currentValue: String,
  };

  static targets = ['autofixSection', 'saveButton', 'autofixButton'];

  declare readonly hasProblematicProjectsValue:boolean;
  declare readonly currentValueValue:string;

  declare readonly autofixSectionTarget:HTMLElement;
  declare readonly saveButtonTarget:HTMLButtonElement;
  declare readonly autofixButtonTarget:HTMLButtonElement;
  declare readonly hasSaveButtonTarget:boolean;

  private readonly resetBeforeCache = ():void => {
    if (this.hasSaveButtonTarget) this.saveButtonTarget.hidden = true;
  };

  connect() {
    document.addEventListener('turbo:before-cache', this.resetBeforeCache);
    this.updateVisibility();
  }

  disconnect() {
    document.removeEventListener('turbo:before-cache', this.resetBeforeCache);
  }

  handleChange() {
    this.updateVisibility();
  }

  private updateVisibility() {
    const selectedValue = this.selectedValue();
    const showAutofix   = selectedValue === 'semantic' && this.hasProblematicProjectsValue;
    const isDirty       = selectedValue !== this.currentValueValue;

    this.autofixSectionTarget.hidden = !showAutofix;
    this.saveButtonTarget.hidden     =  showAutofix || !isDirty;
    this.autofixButtonTarget.hidden  = !showAutofix;
  }

  private selectedValue():string | undefined {
    return this.element.querySelector<HTMLInputElement>(
      'input[name="settings[work_packages_identifier]"]:checked',
    )?.value;
  }
}
