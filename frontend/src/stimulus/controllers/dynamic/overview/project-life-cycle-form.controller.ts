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

import type { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import FormPreviewController from '../../form-preview.controller';
import {
  debounce,
  DebouncedFunc,
} from 'lodash';
import { type TurboBeforeMorphAttributeEvent } from '@hotwired/turbo';
import { useAngularServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

export default class ProjectLifeCycleFormController extends FormPreviewController {
  static services:ServiceKey[] = ['timezone'];

  declare timezone:TimezoneService;

  private deviceService:DeviceService;
  private handleFlatpickrDatesChangedBound = this.handleFlatpickrDatesChanged.bind(this);
  private updateFlatpickrCalendarBound = this.updateFlatpickrCalendar.bind(this);
  private preventValueMorphingActiveElementBound = this.preventValueMorphingActiveElement.bind(this);
  private previewForm:DebouncedFunc<() => void>;

  static targets = ['startDate', 'finishDate', 'duration'];

  declare readonly startDateTarget:HTMLInputElement;
  declare readonly finishDateTarget:HTMLInputElement;
  declare readonly durationTarget:HTMLInputElement;

  private readonly CURRENT_FIELD_CLASS_NAME = 'op-datepicker-modal--date-field_current';

  initialize() {
    super.initialize();
    useAngularServices(this);
  }

  connect() {
    super.connect();

    this.previewForm = debounce(() => {
      if (this.dateInputFieldsAreValid) {
        void this.submit();
      }
    }, 300);

    this.deviceService = new DeviceService();
  }

  // The flatpickr listener reads the timezone service synchronously, so it may
  // only start listening once the service is bound.
  servicesConnected() {
    document.addEventListener('date-picker:flatpickr-dates-changed', this.handleFlatpickrDatesChangedBound);
    document.addEventListener('turbo:before-stream-render', this.updateFlatpickrCalendarBound);
    document.addEventListener('turbo:before-morph-attribute', this.preventValueMorphingActiveElementBound);

    const activeElement = document.activeElement as HTMLInputElement;
    if (activeElement) {
      this.highlightField(activeElement);
    }
  }

  disconnect() {
    document.removeEventListener('date-picker:flatpickr-dates-changed', this.handleFlatpickrDatesChangedBound);
    document.removeEventListener('turbo:before-stream-render', this.updateFlatpickrCalendarBound);
    document.removeEventListener('turbo:before-morph-attribute', this.preventValueMorphingActiveElementBound);
    this.previewForm.cancel();
  }

  onHighlightField(e:Event) {
    const fieldToHighlight = e.target as HTMLInputElement;
    if (fieldToHighlight) {
      this.highlightField(fieldToHighlight);
    }
  }

  private updateFlatpickrCalendar() {
    const dates:Date[] = _.compact(this.dateInputFields.map((field) => this.toDate(field.value)));
    const ignoreNonWorkingDays = false;
    const mode = 'range';

    document.dispatchEvent(
      new CustomEvent('date-picker:flatpickr-set-values', {
        detail: {
          dates,
          ignoreNonWorkingDays,
          mode,
        },
      }),
    );
  }

  handleFlatpickrDatesChanged(event:CustomEvent<{ dates:Date[] }>) {
    const dates = event.detail.dates;

    if (dates.length === 1) {
      const assignFinish = (this.highlightedField === this.finishDateTarget) || this.startDateTarget.disabled;

      const assignTarget = assignFinish ? this.finishDateTarget : this.startDateTarget;
      assignTarget.value = this.dateToIso(dates[0]);

      const highlightTarget = assignFinish && !this.startDateTarget.disabled ? this.startDateTarget : this.finishDateTarget;
      this.highlightField(highlightTarget, true);
    } else {
      this.startDateTarget.value = this.dateToIso(dates[0]);
      this.finishDateTarget.value = this.dateToIso(dates[1]);

      const highlightTarget = this.startDateTarget.disabled ? this.finishDateTarget : this.startDateTarget;
      this.highlightField(highlightTarget, true);
    }

    this.updateFlatpickrCalendar();
    this.previewForm();
  }

  preventValueMorphingActiveElement(event:TurboBeforeMorphAttributeEvent) {
    const target = event.target as HTMLInputElement;
    const { attributeName } = event.detail;
    const isActiveElement = this.highlightedField?.id === target?.id;

    if (isActiveElement && ['value', 'class'].includes(attributeName)) {
      event.preventDefault();
    }
  }

  private get dateInputFieldsAreValid():boolean {
    return this.dateInputFields.every((field) => field.value === '' || this.toDate(field.value));
  }

  private get dateInputFieldsToUpdate():HTMLInputElement[] {
    if (this.highlightedField) {
      return [this.highlightedField];
    }
    return this.dateInputFields;
  }

  private get dateInputFields():HTMLInputElement[] {
    return [this.startDateTarget, this.finishDateTarget];
  }

  private get enabledDateInputFields():HTMLInputElement[] {
    return this.dateInputFields.filter((field) => !field.disabled);
  }

  private get highlightedField():HTMLInputElement|undefined {
    const field = this.dateInputFields.find(
      (el) => el.classList.contains(this.CURRENT_FIELD_CLASS_NAME),
    );

    return field;
  }

  private highlightField(field:HTMLInputElement, clearIfInvalid=false) {
    this.clearHighLight();

    if (field.disabled || !this.dateInputFields.includes(field)) {
      return;
    }

    if (clearIfInvalid && (this.startDateTarget.value > this.finishDateTarget.value)) {
      field.value = '';
    }

    field.classList.add(this.CURRENT_FIELD_CLASS_NAME);
    this.updateFlatpickrCalendar();

    if (this.deviceService.isMobile) {
      window.setTimeout(() => {
        // For mobile, we have to make sure that the active field is scrolled into view after the keyboard is opened
        field.scrollIntoView(true);
      }, 300);
    }
  }

  private clearHighLight() {
    this.dateInputFields
        .forEach((el) => el.classList.remove(this.CURRENT_FIELD_CLASS_NAME));
  }

  private dateToIso(date:Date|null):string {
    if (date) {
      return this.timezone.utcDateToISODateString(date);
    }
    return '';
  }

  private toDate(date:string|null):Date|null {
    if (date && /^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return new Date(date);
    }
    return null;
  }
}
