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

const focusableSelector = 'button, input, select, textarea, a[href]';

export default class SortableController extends Controller<HTMLElement> {
  static targets = ['list', 'section', 'item', 'status', 'itemPosition', 'itemSection', 'fieldSelect', 'sectionTemplate'];

  static values = {
    movedText: { type: String, default: '' },
  };

  declare readonly listTarget:HTMLElement;

  declare readonly sectionTargets:HTMLElement[];

  declare readonly itemTargets:HTMLElement[];

  declare readonly hasStatusTarget:boolean;

  declare readonly statusTarget:HTMLElement;

  declare readonly hasSectionTemplateTarget:boolean;

  declare readonly sectionTemplateTarget:HTMLTemplateElement;

  declare readonly movedTextValue:string;

  move(itemId:string, sectionId:string, index:number):void {
    const item = document.getElementById(itemId);
    const section = document.getElementById(sectionId);
    if (!item || !section) { return; }

    const body = section.querySelector('tbody');
    if (!body) { return; }

    const origin = item.closest<HTMLElement>('[data-screens--sortable-target="section"]');
    const rows = Array.from(body.querySelectorAll<HTMLElement>('[data-screens--sortable-target="item"]'));
    const reference = rows[index] ?? null;
    body.insertBefore(item, reference);
    this.syncPositions(section);
    if (origin && origin !== section) { this.syncPositions(origin); }
    this.syncSectionInputs();
    const position = this.positionOf(item);
    this.announce(item, section, position, rows.length + (rows.includes(item) ? 0 : 1));
    this.focusItem(item);
  }

  up(event:Event):void {
    this.moveWithinSection(event, -1);
  }

  down(event:Event):void {
    this.moveWithinSection(event, 1);
  }

  keydown(event:KeyboardEvent):void {
    if (!event.altKey || (event.key !== 'ArrowUp' && event.key !== 'ArrowDown')) { return; }

    event.preventDefault();
    this.moveWithinSection(event, event.key === 'ArrowUp' ? -1 : 1);
  }

  saveOrder(event:Event):void {
    const section = this.sectionFor(event.target);
    if (!section) { return; }

    this.sortByPosition(section);
    this.syncPositions(section);
    this.syncSectionInputs();
  }

  removeItem(event:Event):void {
    const item = this.itemFor(event.target);
    const section = this.sectionFor(event.target);
    item?.remove();
    if (section) { this.syncPositions(section); }
  }

  removeSection(event:Event):void {
    const section = this.sectionFor(event.target);
    if (!section) { return; }

    // eslint-disable-next-line no-alert
    if (window.confirm(this.statusTarget?.dataset.confirm ?? 'Remove this section?')) {
      section.remove();
    }
  }

  addSection(event:Event):void {
    event.preventDefault();
    if (!this.hasListTarget) { return; }

    const index = this.sectionTargets.length;
    const html = this.hasSectionTemplateTarget
      ? this.sectionTemplateTarget.innerHTML.replace(/__INDEX__/g, String(index))
      : `<fieldset class="screens-section" data-screens--sortable-target="section"><div class="form--field"><input type="text" name="screen[sections][${index}][name]" class="form--text-field"></div></fieldset>`;
    this.listTarget.insertAdjacentHTML('beforeend', html);
    this.focusFirstInput(this.sectionTargets[this.sectionTargets.length - 1]);
  }

  moveWithinSection(event:Event, delta:number):void {
    const item = this.itemFor(event.target);
    const section = this.sectionFor(event.target);
    if (!item || !section) { return; }

    const body = section.querySelector('tbody');
    if (!body) { return; }

    const rows = Array.from(body.querySelectorAll<HTMLElement>('[data-screens--sortable-target="item"]'));
    const index = rows.indexOf(item);
    const next = rows[index + delta];
    if (!next) { return; }

    body.insertBefore(item, delta < 0 ? next : next.nextElementSibling);
    this.syncPositions(section);
    this.syncSectionInputs();
    this.announce(item, section, this.positionOf(item), rows.length);
    this.focusItem(item);
  }

  private syncPositions(section:HTMLElement):void {
    const body = section.querySelector('tbody');
    if (!body) { return; }

    Array.from(body.querySelectorAll<HTMLElement>('[data-screens--sortable-target="item"]')).forEach((item, index) => {
      const input = item.querySelector<HTMLInputElement>('[data-screens--sortable-target="itemPosition"]');
      if (input) { input.value = String(index + 1); }
    });
  }

  private syncSectionInputs():void {
    this.sectionTargets.forEach((section, sectionIndex) => {
      section.querySelectorAll<HTMLInputElement>('[data-screens--sortable-target="itemSection"]').forEach((input) => {
        input.value = section.dataset.sectionId ?? '';
      });
      section.querySelectorAll<HTMLInputElement>('input[name*="[sections]"]').forEach((input) => {
        input.name = input.name.replace(/screen\[sections\]\[\d+\]/, `screen[sections][${sectionIndex}]`);
      });
      section.querySelectorAll<HTMLInputElement>('input[name*="[items]"]').forEach((input) => {
        const item = input.closest<HTMLElement>('[data-screens--sortable-target="item"]');
        const itemIndex = item ? Array.from(section.querySelectorAll('[data-screens--sortable-target="item"]')).indexOf(item) : 0;
        input.name = input.name.replace(/\[items\]\[\d+\]/, `[items][${itemIndex}]`);
      });
    });
  }

  private sortByPosition(section:HTMLElement):void {
    const body = section.querySelector('tbody');
    if (!body) { return; }

    Array.from(body.querySelectorAll<HTMLElement>('[data-screens--sortable-target="item"]'))
      .sort((a, b) => this.positionOf(a) - this.positionOf(b))
      .forEach((item) => body.append(item));
  }

  private positionOf(item:HTMLElement):number {
    const input = item.querySelector<HTMLInputElement>('[data-screens--sortable-target="itemPosition"]');
    return Number(input?.value ?? 0);
  }

  private announce(item:HTMLElement, section:HTMLElement, position:number, total:number):void {
    if (!this.hasStatusTarget) { return; }

    const label = item.dataset.fieldKey ?? '';
    const sectionName = section.querySelector<HTMLInputElement>('input[name*="[name]"]')?.value ?? '';
    this.statusTarget.textContent = this.movedTextValue
      .replace('%{field}', label)
      .replace('%{section}', sectionName)
      .replace('%{position}', String(position))
      .replace('%{total}', String(total));
  }

  private focusItem(item:HTMLElement):void {
    item.focus();
  }

  private focusFirstInput(section:HTMLElement|undefined):void {
    section?.querySelector<HTMLElement>(focusableSelector)?.focus();
  }

  private itemFor(target:EventTarget|null):HTMLElement|null {
    return (target as HTMLElement|null)?.closest<HTMLElement>('[data-screens--sortable-target="item"]') ?? null;
  }

  private sectionFor(target:EventTarget|null):HTMLElement|null {
    return (target as HTMLElement|null)?.closest<HTMLElement>('[data-screens--sortable-target="section"]') ?? null;
  }
}
