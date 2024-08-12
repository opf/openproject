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

export default class BudgetSubformController extends Controller {
  static targets = [
    'template',
    'table',
  ];

  declare readonly templateTarget:HTMLElement;
  declare readonly tableTarget:HTMLTableElement;

  static values = {
    itemCount: Number,
    updateUrl: String,
  };

  declare itemCountValue:number;
  declare updateUrlValue:string;

  private form:HTMLFormElement;
  private submitButtons:NodeListOf<HTMLButtonElement>;

  connect():void {
    this.form = this.element.closest('form') as HTMLFormElement;
    this.submitButtons = this.form.querySelectorAll("button[type='submit']");
  }

  private debounceTimers:{ [id:string]:ReturnType<typeof setTimeout> } = {};

  valueChanged(evt:Event) {
    const row = this.eventRow(evt.target);

    if (row) {
      const id:string = row.getAttribute('id') as string;

      clearTimeout(this.debounceTimers[id]);

      this.debounceTimers[id] = setTimeout(() => {
        void this.refreshRow(id);
      }, 100);
    }
  }

  deleteRow(evt:Event) {
    const row = this.eventRow(evt.target);

    if (row) {
      row.remove();
    }
  }

  addRow() {
    const newRow = this.templateTarget.cloneNode(true);
    this.tableTarget.append(newRow);

    const addedRow = this.tableTarget.lastChild as HTMLElement;
    addedRow.outerHTML = addedRow.outerHTML.replace(/INDEX/g, this.itemCountValue.toString());

    this.itemCountValue += 1;
  }

  /**
   * Refreshes the given row after updating values
   */
  private async refreshRow(row_identifier:string) {
    this.disableForm();

    const response = await fetch(this.updateUrlValue, {
      method: 'POST',
      body: this.buildRefreshRequest(row_identifier),
      headers: { Accept: 'application/json' },
      credentials: 'same-origin',
    });

    const body = await response.json() as Record<string, string>;

    Object.entries(body).forEach(([selector, value]) => {
      const element = document.getElementById(selector) as HTMLElement|HTMLInputElement|undefined;
      if (element instanceof HTMLInputElement) {
        element.value = value;
      } else if (element) {
        element.textContent = value;
      }
    });

    this.enableForm();
  }

  /**
   * Returns the params for the update request
   */
  private buildRefreshRequest(row_identifier:string) {
    const row = this.element.querySelector(`#${row_identifier}`) as HTMLElement;
    const body = new FormData();
    body.append('element_id', row_identifier);
    body.append('fixed_date', (document.querySelector('#budget_fixed_date') as HTMLInputElement).value);

    row.querySelectorAll('.budget-item-value').forEach((itemValue:HTMLInputElement|HTMLSelectElement) => {
      body.append(itemValue.dataset.requestKey as string, (itemValue.value || '0'));
    });

    const csrfTokenTag = document.querySelector("meta[name='csrf-token']");

    if (csrfTokenTag !== null) {
      body.append('authenticity_token', csrfTokenTag.getAttribute('content') as string);
    }

    return body;
  }

  private disableForm() {
    this.submitButtons.forEach((button) => button.setAttribute('disabled', 'disabled'));
  }

  private enableForm() {
    this.submitButtons.forEach((button) => button.removeAttribute('disabled'));
  }

  private eventRow(target:EventTarget|null) {
    return (target as HTMLElement).closest('.cost_entry');
  }
}
