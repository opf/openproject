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

import { Controller } from '@hotwired/stimulus';

export default class BudgetInlineCostEditController extends Controller<HTMLElement> {
  static targets = [
    'editButton',
    'cancelButton',
    'display',
    'input',
    'currency',
    'calculated',
    'hint',
  ];

  static values = {
    isEditing: Boolean,
  };

  declare readonly editButtonTarget:HTMLButtonElement;
  declare readonly cancelButtonTarget:HTMLButtonElement;
  declare readonly displayTarget:HTMLElement;
  declare readonly inputTarget:HTMLInputElement;
  declare readonly currencyTarget:HTMLElement;
  declare readonly calculatedTarget:HTMLElement;
  declare readonly hintTarget:HTMLElement;
  declare readonly hasHintTarget:boolean;

  declare isEditingValue:boolean;

  private rendered = false;

  disconnect() {
    this.rendered = false;
  }

  /**
   * Starts overriding the cost, prefilled with the calculated cost.
   */
  edit() {
    if (this.isEditingValue) {
      return;
    }

    this.inputTarget.value = (this.calculatedTarget.textContent ?? '').trim();
    this.isEditingValue = true;
  }

  /**
   * Drops the override. The input stays enabled but blank, which makes the
   * server clear the override and fall back to the calculated cost.
   */
  cancel(_evt:Event) {
    if (!this.isEditingValue) {
      return;
    }

    this.inputTarget.value = '';
    this.isEditingValue = false;
  }

  /**
   * Keeps Enter in the override input from submitting the whole budget form.
   */
  keepValue(evt:Event) {
    evt.preventDefault();
  }

  isEditingValueChanged(isEditing:boolean, wasEditing:boolean|undefined) {
    const initialRender = !this.rendered;
    this.rendered = true;

    this.inputTarget.hidden = !isEditing;
    this.cancelButtonTarget.hidden = !isEditing;
    this.currencyTarget.hidden = !isEditing;

    this.editButtonTarget.hidden = isEditing;
    this.displayTarget.hidden = isEditing;

    if (this.hasHintTarget) {
      this.hintTarget.hidden = isEditing;
    }

    // Only move focus when the user changed the state, not on connect.
    // Stimulus reports (true, false) on connect for a server-rendered
    // override, so the previous value cannot tell the two apart.
    if (initialRender || wasEditing === isEditing) {
      return;
    }

    if (isEditing) {
      this.inputTarget.focus();
    } else {
      this.editButtonTarget.focus();
    }
  }
}
