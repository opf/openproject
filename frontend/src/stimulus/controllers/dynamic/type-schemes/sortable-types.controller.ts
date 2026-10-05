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

type DropEdge = 'top'|'bottom';

const rowSelector = ':scope > tr';
const focusableSelector = 'button, input, select, textarea, a[href]';

export default class SortableTypesController extends Controller<HTMLElement> {
  static targets = ['list', 'control', 'status'];

  static values = {
    movedText: { type: String, default: '' },
    defaultChangedText: { type: String, default: '' },
  };

  declare readonly listTarget:HTMLElement;

  declare readonly controlTargets:HTMLElement[];

  declare readonly hasStatusTarget:boolean;

  declare readonly statusTarget:HTMLElement;

  declare readonly movedTextValue:string;

  declare readonly defaultChangedTextValue:string;

  private dragged:HTMLTableRowElement|null = null;

  private indicated:HTMLTableRowElement|null = null;

  connect() {
    this.controlTargets.forEach((control) => { control.hidden = false; });
    this.renumber();
    this.syncDefault(false);
  }

  disconnect() {
    this.end();
  }

  start(event:DragEvent) {
    const row = this.rowFor(event.target);
    if (!row) { return; }

    this.dragged = row;
    row.dataset.dragging = 'source';
    row.style.opacity = '0.5';
    if (event.dataTransfer) {
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('text/plain', row.dataset.typeName ?? '');
      event.dataTransfer.setDragImage(row, 10, 10);
    }
  }

  end() {
    this.clearIndicator();
    if (this.dragged) {
      delete this.dragged.dataset.dragging;
      this.dragged.style.opacity = '';
    }
    this.dragged = null;
  }

  over(event:DragEvent) {
    const target = this.rowFor(event.target);
    if (!this.dragged || !target) { return; }

    event.preventDefault();
    if (event.dataTransfer) { event.dataTransfer.dropEffect = 'move'; }

    if (target === this.dragged) {
      this.clearIndicator();
    } else {
      this.showIndicator(target, this.edgeFor(event, target));
    }
  }

  drop(event:DragEvent) {
    const target = this.rowFor(event.target);
    const { dragged } = this;
    if (!dragged || !target || target === dragged) { return; }

    event.preventDefault();
    const edge = this.edgeFor(event, target);
    this.clearIndicator();
    this.listTarget.insertBefore(dragged, edge === 'bottom' ? target.nextElementSibling : target);
    this.renumber();
    this.announce(dragged);
  }

  up(event:Event) {
    this.moveFromControl(event, -1);
  }

  down(event:Event) {
    this.moveFromControl(event, 1);
  }

  keydown(event:KeyboardEvent) {
    if (!event.altKey || (event.key !== 'ArrowUp' && event.key !== 'ArrowDown')) { return; }

    event.preventDefault();
    const row = this.rowFor(event.target);
    const focused = (event.target as HTMLElement|null)?.closest<HTMLElement>(focusableSelector) ?? null;
    if (row) { this.move(row, event.key === 'ArrowUp' ? -1 : 1, focused); }
  }

  toggle() {
    this.syncDefault(true);
  }

  private moveFromControl(event:Event, delta:number) {
    const control = event.currentTarget as HTMLElement|null;
    const row = this.rowFor(control);
    if (row) { this.move(row, delta, control); }
  }

  private move(row:HTMLTableRowElement, delta:number, focusAfter:HTMLElement|null) {
    const rows = this.currentRows();
    const swapWith = rows[rows.indexOf(row) + delta];
    if (!swapWith) { return; }

    this.listTarget.insertBefore(row, delta < 0 ? swapWith : swapWith.nextElementSibling);
    this.renumber();
    this.announce(row);
    focusAfter?.focus();
  }

  private currentRows():HTMLTableRowElement[] {
    return Array.from(this.listTarget.querySelectorAll<HTMLTableRowElement>(rowSelector));
  }

  private rowFor(target:EventTarget|null):HTMLTableRowElement|null {
    return (target as HTMLElement|null)?.closest<HTMLTableRowElement>('tr') ?? null;
  }

  private edgeFor(event:DragEvent, row:HTMLElement):DropEdge {
    const rect = row.getBoundingClientRect();
    return event.clientY > rect.top + (rect.height / 2) ? 'bottom' : 'top';
  }

  private showIndicator(row:HTMLTableRowElement, edge:DropEdge) {
    if (this.indicated && this.indicated !== row) { this.clearIndicator(); }

    this.indicated = row;
    row.dataset.dropPosition = edge;
    const shadow = `inset 0 ${edge === 'top' ? '' : '-'}2px 0 0 var(--fgColor-accent)`;
    row.querySelectorAll<HTMLElement>('td, th').forEach((cell) => { cell.style.boxShadow = shadow; });
  }

  private clearIndicator() {
    if (!this.indicated) { return; }

    delete this.indicated.dataset.dropPosition;
    this.indicated.querySelectorAll<HTMLElement>('td, th').forEach((cell) => { cell.style.boxShadow = ''; });
    this.indicated = null;
  }

  private renumber() {
    this.currentRows().forEach((row, index) => {
      const input = row.querySelector<HTMLInputElement>('input[name$="[position]"]');
      if (input) { input.value = String(index + 1); }
    });
  }

  private syncDefault(announceChange:boolean) {
    const enabledRows = this.currentRows().filter((row) => this.enabledBox(row)?.checked);
    this.currentRows().forEach((row) => {
      const radio = this.defaultRadio(row);
      if (!radio) { return; }

      radio.disabled = !this.enabledBox(row)?.checked;
      if (radio.disabled) { radio.checked = false; }
    });

    const hasDefault = enabledRows.some((row) => this.defaultRadio(row)?.checked);
    const fallback = enabledRows[0];
    if (hasDefault || !fallback) { return; }

    const radio = this.defaultRadio(fallback);
    if (!radio) { return; }

    radio.checked = true;
    if (announceChange) {
      this.say(this.defaultChangedTextValue.replace('%{type}', fallback.dataset.typeName ?? ''));
    }
  }

  private enabledBox(row:HTMLElement):HTMLInputElement|null {
    return row.querySelector<HTMLInputElement>('input[type="checkbox"]');
  }

  private defaultRadio(row:HTMLElement):HTMLInputElement|null {
    return row.querySelector<HTMLInputElement>('input[type="radio"][name$="[default_type_id]"]');
  }

  private announce(row:HTMLTableRowElement) {
    const rows = this.currentRows();
    this.say(this.movedTextValue
      .replace('%{type}', row.dataset.typeName ?? '')
      .replace('%{position}', String(rows.indexOf(row) + 1))
      .replace('%{total}', String(rows.length)));
  }

  private say(message:string) {
    if (this.hasStatusTarget) { this.statusTarget.textContent = message; }
  }
}
