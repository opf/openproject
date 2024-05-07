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
import { compact } from 'lodash';

export default class SortByConfigController extends Controller {
  static targets = [
    'sortByField',
    'inputRow',
    'inputRowContainer',
  ];

  declare readonly sortByFieldTarget:HTMLInputElement;
  declare readonly inputRowTargets:HTMLElement[];
  declare readonly inputRowContainerTarget:HTMLElement;

  connect():void {
    this.inputRowTargets.forEach((row, index) => {
      const selectedField = this.getSelectedField(row);
      const selectedDirection = this.getSelectedDirection(row);

      if (!selectedField) {
        this.hideRow(row);
      } else if (!selectedDirection) {
        this.setDirection(row, 'asc');
      }

      this.displayNewFieldSelectorIfNeeded();
      this.disableOptions();
    });
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
    const row = target.closest('.op-configure-query-sort-form') as HTMLElement;

    const selectedField = this.getSelectedField(row);
    const getSelectedDirection = this.getSelectedDirection(row);

    if (!selectedField) {
    // we have deselected the field, so we need to unset the direction, remove the row and move it to the end of the list
      this.moveRowToBottom(row);
      this.unsetDirection(row);

      if (this.visibleFieldCount() > 1) {
        this.hideRow(row);
      }
    } else if (!getSelectedDirection) {
      // if we have selected a field but no direction, we default to ascending
      this.setDirection(row, 'asc');
    }

    this.displayNewFieldSelectorIfNeeded();

    this.disableOptions();
    this.sortByFieldTarget.value = this.buildSortJson();
    console.log({ visible: this.visibleFieldCount(), order: this.inputRowTargets.map((iRow) => iRow.dataset.index) });
  }

  displayNewFieldSelectorIfNeeded():void {
    // figure out if we need to display a new input field
    const nextHiddenRow = this.firstHiddenRow();

    // we have not reached the maximum number of visible fields, and there is no visible empty field, display a new one
    if (nextHiddenRow && !this.anyRowVisibleWithoutSelectedField()) {
      this.showRow(nextHiddenRow);
    }
  }

  visibleFieldCount():number {
    return this.inputRowTargets.filter((row) => row.style.display !== 'none').length;
  }

  firstHiddenRow():HTMLElement|null {
    return this.inputRowTargets.find((row) => row.style.display === 'none') || null;
  }

  anyRowVisibleWithoutSelectedField():boolean {
    return this.inputRowTargets.some((row) => row.style.display !== 'none' && !this.getSelectedField(row));
  }

  getSelectedField(row:HTMLElement):string|null {
    const selectedField = row.querySelector('select[name="sort_field"]') as HTMLSelectElement;
    return selectedField?.value || null;
  }

  getSelectedDirection(row:HTMLElement):string|null {
    const selectedSegment = row.querySelector('li.SegmentedControl-item--selected > button');
    return selectedSegment?.getAttribute('data-direction') || null;
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

  showRow(row:HTMLElement):void {
    row.style.display = '';
  }

  hideRow(row:HTMLElement):void {
    row.style.display = 'none';
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
    const surroundingDiv = row.parentElement as HTMLElement;
    surroundingDiv.remove();
    this.inputRowContainerTarget.append(surroundingDiv);
  }

  disableOptions():void {
    this.inputRowTargets.forEach((row) => {
      const selectedFieldsInOtherRows = this.getAllSelectedFields(row);
      const otherSelect = row.querySelector('select[name="sort_field"]') as HTMLSelectElement;
      otherSelect.querySelectorAll('option').forEach((option) => {
        option.disabled = selectedFieldsInOtherRows.includes(option.value);
      });
    });
  }
}
