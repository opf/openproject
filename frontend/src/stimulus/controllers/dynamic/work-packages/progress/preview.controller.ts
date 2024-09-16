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
import { debounce, DebouncedFunc } from 'lodash';
import Idiomorph from 'idiomorph/dist/idiomorph.cjs';

interface TurboBeforeFrameRenderEventDetail {
  render:(currentElement:HTMLElement, newElement:HTMLElement) => void;
}

export default class PreviewController extends Controller {
  static targets = [
    'form',
    'progressInput',
    'initialValueInput',
    'touchedFieldInput',
  ];

  declare readonly progressInputTargets:HTMLInputElement[];
  declare readonly formTarget:HTMLFormElement;
  declare readonly initialValueInputTargets:HTMLInputElement[];
  declare readonly touchedFieldInputTargets:HTMLInputElement[];

  private debouncedPreview:DebouncedFunc<(event:Event) => void>;
  private frameMorphRenderer:(event:CustomEvent<TurboBeforeFrameRenderEventDetail>) => void;
  private targetFieldName:string;

  connect() {
    this.debouncedPreview = debounce((event:Event) => { void this.preview(event); }, 100);
    // TODO: Ideally morphing in this single controller should not be necessary.
    // Turbo supports morphing, by adding the <turbo-frame refresh="morph"> attribute.
    // However, it has a bug, and it doesn't morphs when reloading the frame via javascript.
    // See https://github.com/hotwired/turbo/issues/1161 . Once the issue is solved, we can remove
    // this code and just use <turbo-frame refresh="morph"> instead.
    this.frameMorphRenderer = (event:CustomEvent<TurboBeforeFrameRenderEventDetail>) => {
      event.detail.render = (currentElement:HTMLElement, newElement:HTMLElement) => {
        Idiomorph.morph(currentElement, newElement, { ignoreActiveValue: true });
      };
    };

    this.progressInputTargets.forEach((target) => {
      if (target.tagName.toLowerCase() === 'select') {
        target.addEventListener('change', this.debouncedPreview);
      } else {
        target.addEventListener('input', this.debouncedPreview);
      }
      target.addEventListener('blur', this.debouncedPreview);
    });

    const turboFrame = this.formTarget.closest('turbo-frame') as HTMLFrameElement;
    turboFrame.addEventListener('turbo:before-frame-render', this.frameMorphRenderer);
  }

  disconnect() {
    this.debouncedPreview.cancel();
    this.progressInputTargets.forEach((target) => {
      if (target.tagName.toLowerCase() === 'select') {
        target.removeEventListener('change', this.debouncedPreview);
      } else {
        target.removeEventListener('input', this.debouncedPreview);
      }
      target.removeEventListener('blur', this.debouncedPreview);
    });
    const turboFrame = this.formTarget.closest('turbo-frame') as HTMLFrameElement;
    if (turboFrame) {
      turboFrame.removeEventListener('turbo:before-frame-render', this.frameMorphRenderer);
    }
  }

  markFieldAsTouched(event:{ target:HTMLInputElement }) {
    this.targetFieldName = event.target.name.replace(/^work_package\[([^\]]+)\]$/, '$1');
    this.markTouched(this.targetFieldName);

    if (this.isWorkBasedMode()) {
      this.keepWorkValue();
    }
  }

  async preview(event:Event) {
    let field:HTMLInputElement;
    if (event.type === 'blur') {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      field = (event as FocusEvent).relatedTarget as HTMLInputElement;
    } else {
      field = event.target as HTMLInputElement;
    }

    const form = this.formTarget;
    const formData = new FormData(form) as unknown as undefined;
    const formParams = new URLSearchParams(formData);
    const wpParams = [
      ['work_package[initial][estimated_hours]', formParams.get('work_package[initial][estimated_hours]') || ''],
      ['work_package[initial][remaining_hours]', formParams.get('work_package[initial][remaining_hours]') || ''],
      ['work_package[initial][done_ratio]', formParams.get('work_package[initial][done_ratio]') || ''],
      ['work_package[estimated_hours]', formParams.get('work_package[estimated_hours]') || ''],
      ['work_package[remaining_hours]', formParams.get('work_package[remaining_hours]') || ''],
      ['work_package[done_ratio]', formParams.get('work_package[done_ratio]') || ''],
      ['work_package[status_id]', formParams.get('work_package[status_id]') || ''],
      ['field', field?.name ?? ''],
    ];

    this.progressInputTargets.forEach((progressInput) => {
      const touchedInputName = progressInput.name.replace(']', '_touched]');
      const touchedValue = formParams.get(touchedInputName) || '';
      wpParams.push([touchedInputName, touchedValue]);
    });

    const wpPath = this.ensureValidPathname(form.action);
    const wpAction = wpPath.endsWith('/work_packages/new/progress') ? 'new' : 'edit';

    const editUrl = `${wpPath}/${wpAction}?${new URLSearchParams(wpParams).toString()}`;
    const turboFrame = this.formTarget.closest('turbo-frame') as HTMLFrameElement;

    if (turboFrame) {
      turboFrame.src = editUrl;
    }
  }

  // Ensures that on create forms, there is an "id" for the un-persisted
  // work package when sending requests to the edit action for previews.
  private ensureValidPathname(formAction:string):string {
    const wpPath = new URL(formAction);

    if (wpPath.pathname.endsWith('/work_packages/progress')) {
      // Replace /work_packages/progress with /work_packages/new/progress
      wpPath.pathname = wpPath.pathname.replace('/work_packages/progress', '/work_packages/new/progress');
    }

    return wpPath.toString();
  }

  private isWorkBasedMode() {
    return this.findValueInput('done_ratio') !== undefined;
  }

  private keepWorkValue() {
    if (this.isInitialValueEmpty('estimated_hours') && !this.isTouched('estimated_hours')) {
      // let work be derived
      return;
    }

    if (this.isBeingEdited('estimated_hours')) {
      this.untouchFieldsWhenWorkIsEdited();
    } else if (this.isBeingEdited('remaining_hours')) {
      this.untouchFieldsWhenRemainingWorkIsEdited();
    } else if (this.isBeingEdited('done_ratio')) {
      this.untouchFieldsWhenPercentCompleteIsEdited();
    }
  }

  private untouchFieldsWhenWorkIsEdited() {
    if (this.areBothTouched('remaining_hours', 'done_ratio')) {
      if (this.isValueEmpty('done_ratio') && this.isValueEmpty('remaining_hours')) {
        return;
      }
      if (this.isValueEmpty('done_ratio')) {
        this.markUntouched('done_ratio');
      } else {
        this.markUntouched('remaining_hours');
      }
    } else if (this.isTouchedAndEmpty('remaining_hours') && this.isValueSet('done_ratio')) {
      // force remaining work derivation
      this.markUntouched('remaining_hours');
      this.markTouched('done_ratio');
    } else if (this.isTouchedAndEmpty('done_ratio') && this.isValueSet('remaining_hours')) {
      // force % complete derivation
      this.markUntouched('done_ratio');
      this.markTouched('remaining_hours');
    }
  }

  private untouchFieldsWhenRemainingWorkIsEdited() {
    if (this.isTouchedAndEmpty('estimated_hours') && this.isValueSet('done_ratio')) {
      // force work derivation
      this.markUntouched('estimated_hours');
      this.markTouched('done_ratio');
    } else if (this.isValueSet('estimated_hours')) {
      this.markUntouched('done_ratio');
    }
  }

  private untouchFieldsWhenPercentCompleteIsEdited() {
    if (this.isValueSet('estimated_hours')) {
      this.markUntouched('remaining_hours');
    }
  }

  private areBothTouched(fieldName1:string, fieldName2:string) {
    return this.isTouched(fieldName1) && this.isTouched(fieldName2);
  }

  private isBeingEdited(fieldName:string) {
    return fieldName === this.targetFieldName;
  }

  // Finds the hidden initial value input based on a field name.
  //
  // The initial value input field holds the initial value of the work package
  // before being set by the user or derived.
  private findInitialValueInput(fieldName:string):HTMLInputElement|undefined {
    return this.initialValueInputTargets.find((input) =>
      (input.dataset.referrerField === fieldName) || (input.dataset.referrerField === `work_package[${fieldName}]`));
  }

  // Finds the touched field input based on a field name.
  //
  // The touched input field is used to mark a field as touched by the user so
  // that the backend keeps the value instead of deriving it.
  private findTouchedInput(fieldName:string):HTMLInputElement|undefined {
    return this.touchedFieldInputTargets.find((input) =>
      (input.dataset.referrerField === fieldName) || (input.dataset.referrerField === `work_package[${fieldName}]`));
  }

  // Finds the value field input based on a field name.
  //
  // The value field input holds the current value of a progress field.
  private findValueInput(fieldName:string):HTMLInputElement|undefined {
    return this.progressInputTargets.find((input) =>
      (input.name === fieldName) || (input.name === `work_package[${fieldName}]`));
  }

  private isTouchedAndEmpty(fieldName:string) {
    return this.isTouched(fieldName) && this.isValueEmpty(fieldName);
  }

  private isTouched(fieldName:string) {
    const touchedInput = this.findTouchedInput(fieldName);
    return touchedInput?.value === 'true';
  }

  private isInitialValueEmpty(fieldName:string) {
    const valueInput = this.findInitialValueInput(fieldName);
    return valueInput?.value === '';
  }

  private isValueEmpty(fieldName:string) {
    const valueInput = this.findValueInput(fieldName);
    return valueInput?.value === '';
  }

  private isValueSet(fieldName:string) {
    const valueInput = this.findValueInput(fieldName);
    return valueInput !== undefined && valueInput.value !== '';
  }

  private markTouched(fieldName:string) {
    const touchedInput = this.findTouchedInput(fieldName);
    if (touchedInput) {
      touchedInput.value = 'true';
    }
  }

  private markUntouched(fieldName:string) {
    const touchedInput = this.findTouchedInput(fieldName);
    if (touchedInput) {
      touchedInput.value = 'false';
    }
  }
}
