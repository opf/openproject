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
import type { FrameElement, TurboBeforeFrameRenderEvent } from '@hotwired/turbo';
import { Idiomorph } from 'idiomorph';

export abstract class DialogPreviewController extends Controller {
  static targets = [
    'form',
    'fieldInput',
    'initialValueInput',
    'touchedFieldInput',
  ];

  declare readonly fieldInputTargets:HTMLInputElement[];
  declare readonly formTarget:HTMLFormElement;
  declare readonly initialValueInputTargets:HTMLInputElement[];
  declare readonly touchedFieldInputTargets:HTMLInputElement[];

  protected frameMorphRenderer:(event:TurboBeforeFrameRenderEvent) => void;
  protected targetFieldName:string;
  protected touchedFields:Set<string>;

  connect() {
    this.touchedFields = new Set();
    this.touchedFieldInputTargets.forEach((input) => {
      const fieldName = input.dataset.referrerField;
      if (fieldName && input.value === 'true') {
        this.touchedFields.add(fieldName);
      }
    });

    // Turbo supports morphing, by adding the <turbo-frame refresh="morph">
    // attribute. However, it does not work that well with primer input: when
    // adding "data-turbo-permanent" to keep value and focus on the active
    // element, it also keeps the `aria-describedby` attribute which references
    // caption and validation element ids. As these elements are morphed and get
    // new ids, the ids referenced by `aria-describedby` are stale. This makes
    // caption and validation message unaccessible for screen readers and other
    // assistive technologies. This is why morph cannot be used here.
    this.frameMorphRenderer = (event:TurboBeforeFrameRenderEvent) => {
      const target = event.target as FrameElement;
      const requestUrl = new URL(target.src || '', window.location.origin);
      // Do not replace the angular datepicker unless the schedule_manually flag is changed.
      const schedulingChanged = requestUrl.searchParams.has('schedule_manually');

      event.detail.render = (currentElement, newElement) => {
        Idiomorph.morph(currentElement, newElement, {
          ignoreActiveValue: this.ignoreActiveValueWhenMorphing(),
          callbacks: {
            beforeNodeMorphed: (oldNode, newNode) => {
              // In case the element is an OpenProject custom dom element, prevent morphing and
              // replace the angular tag with the new version.
              if (oldNode.tagName?.startsWith('OPCE-')) {
                if (schedulingChanged) {
                  oldNode.replaceWith(newNode);
                }
                return false;
              }
              return true;
            },
          },
        });
        this.afterRendering({ shouldFocusBanner: schedulingChanged });
      };
    };

    this.fieldInputTargets.forEach((target) => {
     if (target.dataset.focus === 'true') {
        this.focusAndSetCursorPositionToEndOfInput(target);
      }
    });

    const turboFrame = this.formTarget.closest('turbo-frame');
    turboFrame?.addEventListener('turbo:before-frame-render', this.frameMorphRenderer);
  }

  disconnect() {
    const turboFrame = this.formTarget.closest('turbo-frame');
    turboFrame?.removeEventListener('turbo:before-frame-render', this.frameMorphRenderer);
  }

  protected cancel():void {
    document.dispatchEvent(new CustomEvent('cancelModalWithTurboContent'));
  }

  markFieldAsTouched(event:{ target:HTMLInputElement }) {
    const fieldName = event.target.name.replace(/^work_package\[([^\]]+)\]$/, '$1');
    this.doMarkFieldAsTouched(fieldName);
  }

  doMarkFieldAsTouched(fieldName:string) {
    this.targetFieldName = fieldName;
    this.markTouched(this.targetFieldName);
  }

  async preview(field:HTMLInputElement|null, additionalData?:{ key:string, val:string }[]) {
    const form = this.formTarget;
    const formData = new FormData(form) as unknown as undefined;
    const formParams = new URLSearchParams(formData);

    const wpParams = Array.from(formParams.entries())
      .filter(([key, _]) => key.startsWith('work_package'));
    wpParams.push(['field', field?.name ?? '']);

    if (additionalData) {
      additionalData.forEach((data) => {
        wpParams.push([data.key, data.val]);
      });
    }

    const previewUrl = `${form.action}/preview?${new URLSearchParams(wpParams).toString()}`;
    const turboFrame = this.formTarget.closest('turbo-frame');

    if (turboFrame) {
      turboFrame.src = previewUrl;
    }
  }

  private isUpdatingWorkPackage(formPath:string):boolean {
    const workPackagePathRegex = /\/work_packages\/\d+\//;
    return workPackagePathRegex.test(formPath);
  }

  protected focusAndSetCursorPositionToEndOfInput(field:HTMLInputElement) {
    field.focus();
    if (field.type === 'text') {
      field.setSelectionRange(
        field.value.length,
        field.value.length,
      );
    }
  }

  abstract afterRendering(params?:object):void;

  // Whether to ignore the active element value when morphing.
  abstract ignoreActiveValueWhenMorphing():boolean;

  protected isBeingEdited(fieldName:string) {
    return fieldName === this.targetFieldName;
  }

  // Finds the hidden initial value input based on a field name.
  //
  // The initial value input field holds the initial value of the work package
  // before being set by the user or derived.
  private findInitialValueInput(fieldName:string):HTMLInputElement|undefined {
    return this.initialValueInputTargets.find((input) =>
      (input.dataset.referrerField === fieldName));
  }

  // Finds the value field input based on a field name.
  //
  // The value field input holds the current value of a field.
  protected findValueInput(fieldName:string):HTMLInputElement|undefined {
    return this.fieldInputTargets.find((input) =>
      (input.name === fieldName) || (input.name === `work_package[${fieldName}]`));
  }

  protected isTouchedAndEmpty(fieldName:string):boolean {
    return this.isTouched(fieldName) && this.isValueEmpty(fieldName);
  }

  protected isTouched(fieldName:string):boolean {
    return this.touchedFields.has(fieldName);
  }

  protected areBothTouched(fieldName1:string, fieldName2:string):boolean {
    return this.isTouched(fieldName1) && this.isTouched(fieldName2);
  }

  protected isInitialValueEmpty(fieldName:string):boolean {
    const valueInput = this.findInitialValueInput(fieldName);
    return valueInput?.value === '';
  }

  protected isValueEmpty(fieldName:string):boolean {
    const valueInput = this.findValueInput(fieldName);
    return valueInput?.value === '';
  }

  protected isValueSet(fieldName:string):boolean {
    const valueInput = this.findValueInput(fieldName);
    return valueInput !== undefined && valueInput.value !== '';
  }

  protected markTouched(fieldName:string):void {
    this.touchedFields.add(fieldName);
    this.updateTouchedFieldHiddenInputs();
  }

  protected markUntouched(fieldName:string):void {
    this.touchedFields.delete(fieldName);
    this.updateTouchedFieldHiddenInputs();
  }

  private updateTouchedFieldHiddenInputs():void {
    this.touchedFieldInputTargets.forEach((input) => {
      const fieldName = input.dataset.referrerField;
      if (fieldName) {
        input.value = this.isTouched(fieldName) ? 'true' : 'false';
      }
    });
  }
}
