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

export default class DailyRemindersController extends Controller {
  static targets = ['list', 'row', 'rowTemplate'];

  declare readonly listTarget:HTMLElement;
  declare readonly rowTargets:HTMLElement[];
  declare readonly rowTemplateTarget:HTMLTemplateElement;
  declare readonly hasRowTemplateTarget:boolean;

  private readonly handleChange = ():void => { this.syncDisabledOptions(); };

  connect():void {
    this.listTarget.addEventListener('change', this.handleChange);
    this.syncDisabledOptions();
    this.updateRemoveButtons();
  }

  disconnect():void {
    this.listTarget.removeEventListener('change', this.handleChange);
  }

  addTime():void {
    if (!this.hasRowTemplateTarget) return;

    const clone = this.rowTemplateTarget.content.cloneNode(true) as DocumentFragment;
    this.listTarget.appendChild(clone);
    this.syncDisabledOptions();
    this.updateRemoveButtons();
  }

  removeTime(event:Event):void {
    const button = event.currentTarget as HTMLElement;
    button.closest('[data-my--daily-reminders-target="row"]')?.remove();
    this.syncDisabledOptions();
    this.updateRemoveButtons();
  }

  private updateRemoveButtons():void {
    const rows = this.rowTargets;
    const showRemove = rows.length > 1;
    rows.forEach((row) => {
      const btn = row.querySelector<HTMLElement>('[data-action="my--daily-reminders#removeTime"]');
      if (btn) btn.hidden = !showRemove;
    });
  }

  private syncDisabledOptions():void {
    const selects = Array.from(this.listTarget.querySelectorAll<HTMLSelectElement>('select'));
    const selectedValues = new Set(selects.map((s) => s.value));

    selects.forEach((select) => {
      Array.from(select.options).forEach((option) => {
        option.disabled = selectedValues.has(option.value) && option.value !== select.value;
      });
    });
  }
}
