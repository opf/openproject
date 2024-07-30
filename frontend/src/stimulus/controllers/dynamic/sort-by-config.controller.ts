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
import { compact } from 'lodash';

export default class SortByConfigController extends Controller {
  static targets = [
    'sortByField',
    'inputRow',
    'inputRowContainer',
  ];

  // These fields can only be selected in isolation. When this field is selected, no other option is allowed to be selected
  static onlySelectableInIsolation = ['lft'];

  // For some fields we must enforce a fixed direction, those can be listed here
  static fixedDirections:Map<string, string> = new Map([
    ['lft', 'asc'],
  ]);

  declare readonly sortByFieldTarget:HTMLInputElement;
  declare readonly inputRowTargets:HTMLElement[];
  declare readonly inputRowContainerTarget:HTMLElement;

  connect():void {
    this.inputRowTargets.forEach((row) => {
      this.manageRow(row);
    });

    this.displayNewFieldSelectorIfNeeded();
    this.disableSelectedFieldsForOtherSelects();
  }

  buildSortJson():string {
    const filters = this.inputRowTargets.map((row) => {
      const field = this.getSelectedField(row);
      if (field) { return [field, this.getSelectedDirection(row)]; }
      return null;
    });

    return JSON.stringify(compact(filters));
  }

  fieldChanged(event:Event):void {
    const target = event.target as HTMLElement;
    const row = target.closest('div[data-sort-by-config-target="inputRow"]') as HTMLElement;

    this.manageRow(row);

    this.displayNewFieldSelectorIfNeeded();
    this.disableSelectedFieldsForOtherSelects();

    this.sortByFieldTarget.value = this.buildSortJson();
  }

  manageRow(row:HTMLElement):void {
    const selectedField = this.getSelectedField(row);
    const selectedDirection = this.getSelectedDirection(row);

    // we have deselected the field, so we need to unset the direction, remove the row and move it to the end of the list
    if (!selectedField) {
      this.moveRowToBottom(row);
      this.unsetDirection(row);

      if (this.visibleFieldCount() > 1) {
        this.hideRow(row);
      }
    } else {
      // we have selected a field, let's check a few things on it

      // we have added a new field and no direction is set yet, we default to asc
      if (!selectedDirection) {
        this.setDirection(row, 'asc');
      }

      // we have selected a field that requires a fixed direction
      if (selectedField && SortByConfigController.fixedDirections.has(selectedField)) {
        this.setDirection(row, SortByConfigController.fixedDirections.get(selectedField) as string);
        this.toggleDirectionEnabled(row, false);
      } else {
        this.toggleDirectionEnabled(row, true);
      }

      // we have a field that can only be selected in isolation, we need to unset and remove all other fields
      if (this.isIsolatedField(row)) {
        this.inputRowTargets.forEach((otherRow) => {
          if (otherRow !== row) {
            this.hideRow(otherRow);
            this.unsetField(otherRow);
            this.unsetDirection(otherRow);
            this.moveRowToBottom(otherRow);
          }
        });
      }
    }
  }

  displayNewFieldSelectorIfNeeded():void {
    // If an isolated field is selected, we do not want to display a new field
    if (this.anyIsolatedFieldSelected()) { return; }

    // If there is a visible field without a selected field, we do not want to display a new field
    if (this.anyRowVisibleWithoutSelectedField()) { return; }

    // figure out if we need to display a new input field
    const nextHiddenRow = this.firstHiddenRow();

    // we have not reached the maximum number of visible fields, and there is no visible empty field, display a new one
    if (nextHiddenRow) {
      this.showRow(nextHiddenRow);
    }
  }

  anyIsolatedFieldSelected():boolean {
    return this.inputRowTargets.some((row) => this.isIsolatedField(row));
  }

  isIsolatedField(row:HTMLElement):boolean {
    const selectedField = this.getSelectedField(row);
    if (!selectedField) { return false; }

    return SortByConfigController.onlySelectableInIsolation.includes(selectedField);
  }

  visibleFieldCount():number {
    return this.inputRowTargets.filter((row) => this.rowIsVisible(row)).length;
  }

  firstHiddenRow():HTMLElement|null {
    return this.inputRowTargets.find((row) => !this.rowIsVisible(row)) || null;
  }

  anyRowVisibleWithoutSelectedField():boolean {
    return this.inputRowTargets.some((row) => this.rowIsVisible(row) && !this.getSelectedField(row));
  }

  getSelectedField(row:HTMLElement):string|null {
    const selectedField = row.querySelector('select[name="sort_field"]') as HTMLSelectElement;
    return selectedField?.value || null;
  }

  getSelectedDirection(row:HTMLElement):string|null {
    const selectedSegment = row.querySelector('li.SegmentedControl-item--selected > button');
    return selectedSegment?.getAttribute('data-direction') || null;
  }

  unsetField(row:HTMLElement):void {
    const select = row.querySelector('select[name="sort_field"]') as HTMLSelectElement;
    select.value = '';
  }

  unsetDirection(row:HTMLElement):void {
    const segmentControls = row.querySelectorAll('li.SegmentedControl-item');
    segmentControls.forEach((control) => {
      control.classList.remove('SegmentedControl-item--selected');
      control.querySelector('button')?.setAttribute('aria-current', 'false');
    });
  }

  setDirection(row:HTMLElement, direction:string):void {
    const segmentControls = row.querySelectorAll('li.SegmentedControl-item');

    segmentControls.forEach((control) => {
      const button = control.querySelector('button') as HTMLButtonElement;

      if (button.getAttribute('data-direction') === direction) {
        control.classList.add('SegmentedControl-item--selected');
        button.setAttribute('aria-current', 'true');
      } else {
        control.classList.remove('SegmentedControl-item--selected');
        button.setAttribute('aria-current', 'false');
      }
    });
  }

  toggleDirectionEnabled(row:HTMLElement, enabled:boolean):void {
    const segmentControls = row.querySelectorAll('li.SegmentedControl-item');
    segmentControls.forEach((control) => {
      const button = control.querySelector('button') as HTMLButtonElement;
      button.disabled = !enabled;
    });
  }

  rowIsVisible(row:HTMLElement):boolean {
    return !row.classList.contains('d-none');
  }

  showRow(row:HTMLElement):void {
    row.classList.remove('d-none');
  }

  hideRow(row:HTMLElement):void {
    row.classList.add('d-none');
  }

  getAllSelectedFields(...excludedRows:HTMLElement[]):string[] {
    return compact(this.inputRowTargets.map((row) => {
      if (!excludedRows.includes(row)) {
        return this.getSelectedField(row);
      }
      return null;
    }));
  }

  moveRowToBottom(row:HTMLElement):void {
    row.remove();
    this.inputRowContainerTarget.append(row);
  }

  disableSelectedFieldsForOtherSelects():void {
    this.inputRowTargets.forEach((row) => {
      const selectedFieldsInOtherRows = this.getAllSelectedFields(row);
      const otherSelect = row.querySelector('select[name="sort_field"]') as HTMLSelectElement;
      otherSelect.querySelectorAll('option').forEach((option) => {
        option.disabled = selectedFieldsInOtherRows.includes(option.value);
      });
    });
  }
}
