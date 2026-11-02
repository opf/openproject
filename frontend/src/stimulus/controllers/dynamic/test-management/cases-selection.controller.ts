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

export default class CasesSelectionController extends Controller {
  static targets = [
    'mode',
    'checkboxColumn',
    'rowCheckbox',
    'selectAll',
    'actionBar',
    'count',
    'idsContainer',
  ];

  declare readonly modeTarget:HTMLInputElement;
  declare readonly hasModeTarget:boolean;
  declare readonly rowCheckboxTargets:HTMLInputElement[];
  declare readonly selectAllTarget:HTMLInputElement;
  declare readonly hasSelectAllTarget:boolean;
  declare readonly actionBarTarget:HTMLElement;
  declare readonly hasActionBarTarget:boolean;
  declare readonly countTarget:HTMLElement;
  declare readonly hasCountTarget:boolean;
  declare readonly idsContainerTargets:HTMLElement[];

  connect():void {
    this.refreshCount();
  }

  modeChanged():void {
    if (this.hasModeTarget && !this.modeTarget.checked) {
      this.clearSelection();
    }
    this.refreshCount();
  }

  toggleAll():void {
    if (!this.hasSelectAllTarget) {
      return;
    }

    const checked = this.selectAllTarget.checked;
    this.rowCheckboxTargets.forEach((box) => {
      box.checked = checked;
    });
    this.refreshCount();
  }

  selectionChanged():void {
    this.refreshCount();
    if (!this.hasSelectAllTarget) {
      return;
    }

    const total = this.rowCheckboxTargets.length;
    const selected = this.selectedIds().length;
    this.selectAllTarget.checked = total > 0 && selected === total;
    this.selectAllTarget.indeterminate = selected > 0 && selected < total;
  }

  beforeSubmit(event:Event):void {
    const ids = this.selectedIds();
    if (ids.length === 0) {
      event.preventDefault();
      return;
    }

    this.idsContainerTargets.forEach((container) => {
      container.replaceChildren();
      ids.forEach((id) => {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = 'ids[]';
        input.value = id;
        container.appendChild(input);
      });
    });
  }

  private clearSelection():void {
    this.rowCheckboxTargets.forEach((box) => {
      box.checked = false;
    });
    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = false;
      this.selectAllTarget.indeterminate = false;
    }
  }

  private selectedIds():string[] {
    return this.rowCheckboxTargets
      .filter((box) => box.checked)
      .map((box) => box.value);
  }

  private refreshCount():void {
    if (!this.hasCountTarget) {
      return;
    }

    const count = this.selectedIds().length;
    this.countTarget.textContent = String(count);

    if (!this.hasActionBarTarget) {
      return;
    }

    this.actionBarTarget.classList.toggle('is-disabled', count === 0);
    this.actionBarTarget.querySelectorAll<HTMLButtonElement>('button[type="submit"]').forEach((button) => {
      button.disabled = count === 0;
    });
  }
}
