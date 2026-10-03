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

import { Controller } from '@hotwired/stimulus';

export default class SortableTypesController extends Controller<HTMLElement> {
  static targets = ['list', 'row', 'position', 'control', 'status'];

  static values = { movedText: { type: String, default: '' } };

  declare readonly listTarget:HTMLElement;

  declare readonly rowTargets:HTMLTableRowElement[];

  declare readonly controlTargets:HTMLButtonElement[];

  declare readonly hasStatusTarget:boolean;

  declare readonly statusTarget:HTMLElement;

  declare readonly movedTextValue:string;

  private dragged:HTMLTableRowElement|null = null;

  connect() {
    this.controlTargets.forEach((button) => { button.hidden = false; });
  }

  start(event:DragEvent) {
    const row = this.rowFor(event.target);
    if (!row) { return; }

    this.dragged = row;
    row.setAttribute('data-dragging', 'source');
    if (event.dataTransfer) {
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', row.id || 'type-scheme-row');
      event.dataTransfer.setDragImage(row, 10, 10);
    }
  }

  end() {
    this.dragged?.removeAttribute('data-dragging');
    this.dragged = null;
  }

  over(event:DragEvent) {
    if (!this.dragged) { return; }

    event.preventDefault();
    if (event.dataTransfer) { event.dataTransfer.dropEffect = 'move'; }
  }

  drop(event:DragEvent) {
    const target = this.rowFor(event.target);
    const { dragged } = this;
    if (!dragged || !target || target === dragged) { return; }

    event.preventDefault();
    const rect = target.getBoundingClientRect();
    const after = event.clientY > rect.top + (rect.height / 2);
    this.listTarget.insertBefore(dragged, after ? target.nextElementSibling : target);
    this.renumber();
    this.announce(dragged);
  }

  up(event:Event) {
    this.move(event, -1);
  }

  down(event:Event) {
    this.move(event, 1);
  }

  keydown(event:KeyboardEvent) {
    if (!event.altKey || (event.key !== 'ArrowUp' && event.key !== 'ArrowDown')) { return; }

    event.preventDefault();
    this.move(event, event.key === 'ArrowUp' ? -1 : 1);
  }

  private move(event:Event, delta:number) {
    const row = this.rowFor(event.target);
    if (!row) { return; }

    const rows = this.currentRows();
    const index = rows.indexOf(row);
    const swapWith = rows[index + delta];
    if (!swapWith) { return; }

    this.listTarget.insertBefore(row, delta < 0 ? swapWith : swapWith.nextElementSibling);
    this.renumber();
    this.announce(row);
    (event.target as HTMLElement).focus();
  }

  private currentRows():HTMLTableRowElement[] {
    return Array.from(this.listTarget.querySelectorAll<HTMLTableRowElement>(':scope > tr'));
  }

  private rowFor(target:EventTarget|null):HTMLTableRowElement|null {
    return (target as HTMLElement|null)?.closest<HTMLTableRowElement>('tr') ?? null;
  }

  private renumber() {
    this.currentRows().forEach((row, index) => {
      const input = row.querySelector<HTMLInputElement>('input[name$="[position]"]');
      if (input) { input.value = String(index + 1); }
    });
  }

  private announce(row:HTMLTableRowElement) {
    if (!this.hasStatusTarget) { return; }

    const rows = this.currentRows();
    const name = row.querySelector('td:nth-child(3)')?.textContent?.trim() ?? '';
    this.statusTarget.textContent = this.movedTextValue
      .replace('%{type}', name)
      .replace('%{position}', String(rows.indexOf(row) + 1))
      .replace('%{total}', String(rows.length));
  }
}
