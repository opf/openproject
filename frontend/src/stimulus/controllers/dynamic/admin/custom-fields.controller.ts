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

export default class CustomFieldsController extends Controller {
  static targets = [
    'format',
    'dragContainer',

    'customOptionDefaults',
    'customOptionRow',

    'allowNonOpenVersions',
    'defaultBool',
    'defaultLongText',
    'defaultText',
    'length',
    'multiSelect',
    'possibleValues',
    'regexp',
    'searchable',
    'textOrientation',
  ];

  static values = {
    formatConfig: Array,
  };

  declare readonly formatConfigValue:[string, string, string[]][];

  declare readonly formatTarget:HTMLInputElement;
  declare readonly dragContainerTarget:HTMLElement;
  declare readonly hasDragContainerTarget:boolean;

  declare readonly customOptionDefaultsTargets:HTMLInputElement[];
  declare readonly customOptionRowTargets:HTMLTableRowElement[];

  declare readonly allowNonOpenVersionsTargets:HTMLElement[];
  declare readonly defaultBoolTargets:HTMLElement[];
  declare readonly defaultLongTextTargets:HTMLElement[];
  declare readonly defaultTextTargets:HTMLElement[];
  declare readonly lengthTargets:HTMLElement[];
  declare readonly multiSelectTargets:HTMLElement[];
  declare readonly possibleValuesTargets:HTMLElement[];
  declare readonly regexpTargets:HTMLElement[];
  declare readonly searchableTargets:HTMLInputElement[];
  declare readonly textOrientationTargets:HTMLElement[];

  connect() {
    if (this.hasDragContainerTarget) {
      this.setupDragAndDrop();
    }

    this.formatChanged();
  }

  formatChanged() {
    this.toggleFormat(this.formatTarget.value);
  }

  moveRowUp(event:{ target:HTMLElement }) {
    const row = event.target.closest('tr') as HTMLTableRowElement;
    const idx = this.customOptionRowTargets.indexOf(row);
    if (idx > 0) {
      this.customOptionRowTargets[idx - 1].before(row);
    }

    return false;
  }

  moveRowDown(event:{ target:HTMLElement }) {
    const row = event.target.closest('tr') as HTMLTableRowElement;
    const idx = this.customOptionRowTargets.indexOf(row);
    if (idx < this.customOptionRowTargets.length - 1) {
      this.customOptionRowTargets[idx + 1].after(row);
    }

    return false;
  }

  moveRowToTheTop(event:{ target:HTMLElement }) {
    const row = event.target.closest('tr') as HTMLTableRowElement;
    const first = this.customOptionRowTargets[0];

    if (first && first !== row) {
      first.before(row);
    }

    return false;
  }

  moveRowToTheBottom(event:{ target:HTMLElement }) {
    const row = event.target.closest('tr') as HTMLTableRowElement;
    const last = this.customOptionRowTargets[this.customOptionRowTargets.length - 1];

    if (last && last !== row) {
      last.after(row);
    }

    return false;
  }

  removeOption(event:MouseEvent) {
    const self = event.target as HTMLAnchorElement;
    if (self.href === '#' || self.href.endsWith('/0')) {
      const row = self.closest('tr');

      if (row && this.customOptionRowTargets.length > 1) {
        row.remove();
      }

      event.preventDefault();
      event.stopImmediatePropagation();
    }
    return true; // send off deletion
  }

  addOption() {
    const count = this.customOptionRowTargets.length;
    const last = this.customOptionRowTargets[count - 1];
    const dup = last.cloneNode(true) as HTMLElement;

    const input = dup.querySelector('.custom-option-value input') as HTMLInputElement;

    input.setAttribute('name', `custom_field[custom_options_attributes][${count}][value]`);
    input.setAttribute('id', `custom_field_custom_options_attributes_${count}_value`);
    input.value = '';

    dup
      .querySelector('.custom-option-id')
      ?.remove();

    const defaultValueCheckbox = dup.querySelector('input[type="checkbox"]') as HTMLInputElement;
    const defaultValueHidden = dup.querySelector('input[type="hidden"]') as HTMLInputElement;

    defaultValueHidden.setAttribute('name', `custom_field[custom_options_attributes][${count}][default_value]`);
    defaultValueHidden.removeAttribute('id');
    defaultValueCheckbox.setAttribute('name', `custom_field[custom_options_attributes][${count}][default_value]`);
    defaultValueCheckbox.setAttribute('id', `custom_field_custom_options_attributes_${count}_default_value`);
    defaultValueCheckbox.checked = false;

    last.insertAdjacentElement('afterend', dup);

    return false;
  }

  uncheckOtherDefaults(event:{ target:HTMLElement }) {
    const cb = event.target as HTMLInputElement;

    if (cb.checked) {
      const multi = this.multiSelectTargets[0] as HTMLInputElement|undefined;

      if (multi?.checked === false) {
        this.customOptionDefaultsTargets.forEach((el) => (el.checked = false));
        cb.checked = true;
      }
    }
  }

  checkOnlyOne(event:{ target:HTMLElement }) {
    const cb = event.target as HTMLInputElement;

    if (!cb.checked) {
      this.customOptionDefaultsTargets
        .filter((el) => el.checked)
        .slice(1)
        .forEach((el) => (el.checked = false));
    }
  }

  private setupDragAndDrop() {
    // Make custom fields draggable
    // eslint-disable-next-line no-undef
    const drake = dragula([this.dragContainerTarget], {
      isContainer: () => false,
      moves: (el, source, handle:HTMLElement) => handle.classList.contains('dragula-handle'),
      accepts: () => true,
      invalid: () => false,
      direction: 'vertical',
      copy: false,
      copySortSource: false,
      revertOnSpill: true,
      removeOnSpill: false,
      mirrorContainer: this.dragContainerTarget,
      ignoreInputTextSelection: true,
    });

    // Setup autoscroll
    void window.OpenProject.getPluginContext().then((pluginContext) => {
      // eslint-disable-next-line no-new
      new pluginContext.classes.DomAutoscrollService(
        [
          document.getElementById('content-body') as HTMLElement,
        ],
        {
          margin: 25,
          maxSpeed: 10,
          scrollWhenOutside: true,
          autoScroll: () => drake.dragging,
        },
      );
    });
  }

  private setActive(elements:HTMLElement[], active:boolean) {
    elements.forEach((element) => {
      element.hidden = !active;
      element
        .querySelectorAll<HTMLInputElement>('input, textarea')
        .forEach((input) => {
          input.disabled = !active;
        });
    });
  }

  private toggleFormat(format:string) {
    this.formatConfigValue.forEach(([targetsName, operator, formats]) => {
      const active = operator === 'only' ? formats.includes(format) : !formats.includes(format);
      const targets = this[`${targetsName}Targets` as keyof typeof this] as HTMLElement[];
      if (targets) {
        this.setActive(targets, active);
      }
    });
  }
}
