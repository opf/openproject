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

import { DialogPreviewController } from '../dialog/preview.controller';
import type { TimezoneService } from 'core-app/core/datetime/timezone.service';
import {
  debounce,
  DebouncedFunc,
} from 'lodash';
import { useAngularServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

export default class PreviewController extends DialogPreviewController {
  static services:ServiceKey[] = ['timezone'];

  static values = {
    dateMode: String,
    triggeringField: String,
    scheduleManually: Boolean,
  };

  declare dateModeValue:string;
  declare triggeringFieldValue:string;
  declare scheduleManuallyValue:boolean;

  declare timezone:TimezoneService;

  private highlightedField:HTMLInputElement|null = null;

  // The field values currently used by the controller
  private currentIgnoreNonWorkingDays = false;
  private currentStartDate:Date|null = null;
  private currentDueDate:Date|null = null;
  private currentDuration:number|null = null;

  private isMilestone = true;

  private handleFlatpickrDatesChangedBound = this.handleFlatpickrDatesChanged.bind(this);

  private debouncedDelayedPreview:DebouncedFunc<(input:HTMLInputElement) => void>;
  private debouncedImmediatePreview:DebouncedFunc<(input:HTMLInputElement) => void>;

  initialize() {
    useAngularServices(this);
  }

  connect() {
    // if the debounce value is changed, the following test helper must be kept
    // in sync: `spec/support/edit_fields/progress_edit_field.rb`, method `#wait_for_preview_to_complete`
    this.debouncedDelayedPreview = debounce((input:HTMLInputElement) => {
      void this.preview(input);
    }, 200);
    this.debouncedImmediatePreview = debounce((input:HTMLInputElement) => {
      void this.preview(input);
    }, 0);

    this.readInitialValues();
    super.connect();
  }

  // The flatpickr listener reads the timezone service synchronously, so it may
  // only start listening once the service is bound.
  servicesConnected() {
    document.addEventListener('date-picker:flatpickr-dates-changed', this.handleFlatpickrDatesChangedBound);
    this.focusOnOpen();
  }

  disconnect() {
    document.removeEventListener('date-picker:flatpickr-dates-changed', this.handleFlatpickrDatesChangedBound);

    this.debouncedDelayedPreview.cancel();
    this.debouncedImmediatePreview.cancel();

    super.disconnect();
  }

  async preview(field:HTMLInputElement|null) {
    await super.preview(field, [
      { key: 'date_mode', val: this.dateModeValue },
      { key: 'triggering_field', val: this.triggeringFieldValue },
    ]);
  }

  inputChanged(event:Event) {
    const field = event.target as HTMLInputElement;

    if (field.name === 'work_package[start_date]') {
      if (/^\d{4}-\d{2}-\d{2}$/.test(field.value)) {
        const selectedDate = new Date(field.value);
        this.changeStartDate(selectedDate);
        this.debouncedDelayedPreview(field);
      } else if (field.value === '') {
        this.debouncedDelayedPreview(field);
      }
    } else if (field.name === 'work_package[due_date]') {
      if (/^\d{4}-\d{2}-\d{2}$/.test(field.value)) {
        const selectedDate = new Date(field.value);
        this.changeDueDate(selectedDate);
        this.debouncedDelayedPreview(field);
      } else if (field.value === '') {
        this.debouncedDelayedPreview(field);
      }
    } else {
      this.debouncedDelayedPreview(field);
    }
  }

  private get dueDateField():HTMLInputElement|undefined {
    return document.getElementsByName('work_package[due_date]')[0] as HTMLInputElement|undefined;
  }

  private get startDateField():HTMLInputElement|undefined {
    return document.getElementsByName('work_package[start_date]')[0] as HTMLInputElement;
  }

  private get durationField():HTMLInputElement|undefined {
    return document.getElementsByName('work_package[duration]')[0] as HTMLInputElement;
  }

  handleFlatpickrDatesChanged(event:CustomEvent<{ dates:Date[] }>) {
    const dates = event.detail.dates;
    let fieldUpdatedWithUserValue:HTMLInputElement|null|undefined = null;

    if (this.isMilestone) {
      this.currentStartDate = dates[0];
      this.setStartDateFieldValue(dates[0]);
      this.doMarkFieldAsTouched('start_date');
    } else {
      const selectedDate:Date = this.lastClickedDate(dates) || dates[0];
      let dateFieldToChange = this.dateFieldToChange();
      this.swapDateFieldsIfNeeded(selectedDate, dateFieldToChange);
      dateFieldToChange = this.dateFieldToChange();
      if (dateFieldToChange === this.startDateField) {
        this.changeStartDate(selectedDate);
      } else {
        this.changeDueDate(selectedDate);
      }
      fieldUpdatedWithUserValue = dateFieldToChange;
    }
    this.updateFlatpickrCalendar();
    if (fieldUpdatedWithUserValue) {
      this.debouncedImmediatePreview(fieldUpdatedWithUserValue);
    }
  }

  dateFieldToChange():HTMLInputElement|undefined {
    if (this.isMilestone) {
      return this.startDateField;
    }

    const currentlyHighledField = document.getElementsByClassName('op-datepicker-modal--date-field_current')[0];
    if (currentlyHighledField) {
      this.highlightedField = currentlyHighledField as HTMLInputElement;
    }

    let dateFieldToChange:HTMLInputElement|undefined;
    if (this.highlightedField === this.dueDateField
        || (this.highlightedField === this.durationField && !this.scheduleManuallyValue)
        || (this.highlightedField === this.durationField
        && (this.currentStartDate !== null || !this.isTouched('start_date'))
        && this.currentDueDate === null)) {
      dateFieldToChange = this.dueDateField;
    } else {
      dateFieldToChange = this.startDateField;
    }
    return dateFieldToChange;
  }

  swapDateFieldsIfNeeded(selectedDate:Date, dateFieldToChange:HTMLInputElement|undefined) {
    if (dateFieldToChange === undefined) {
      return;
    }

    // It needs to be swapped if the other field is set, the field to change is
    // unset, and setting it would make start and end be in the wrong order.
    if (
      dateFieldToChange === this.dueDateField
        && this.currentStartDate !== null
        && this.currentDueDate === null
        && selectedDate < this.currentStartDate
    ) {
      this.currentDueDate = this.currentStartDate;
      this.setDueDateFieldValue(this.currentDueDate);
      this.doMarkFieldAsTouched('due_date');
      this.currentStartDate = null;
      this.highlightField(this.startDateField);
    } else if (
      dateFieldToChange === this.startDateField
        && this.currentStartDate === null
        && this.currentDueDate !== null
        && selectedDate > this.currentDueDate
    ) {
      this.currentStartDate = this.currentDueDate;
      this.setStartDateFieldValue(this.currentStartDate);
      this.doMarkFieldAsTouched('start_date');
      this.currentDueDate = null;
      this.highlightField(this.dueDateField);
    }
  }

  changeStartDate(selectedDate:Date) {
    if (this.currentDueDate && this.currentDueDate < selectedDate) {
      // if selectedDate is after due date, due date and duration are cleared first.
      this.currentDueDate = null;
      this.currentDuration = null;
      this.setDueDateFieldValue(this.currentDueDate);
      this.setDurationFieldValue(this.currentDuration);
      this.doMarkFieldAsTouched('due_date');
    }

    this.currentStartDate = selectedDate;
    this.setStartDateFieldValue(this.currentStartDate);
    this.doMarkFieldAsTouched('start_date');

    this.keepFieldValue();
  }

  changeDueDate(selectedDate:Date) {
    // if selectedDate is before start date, start date and duration are cleared first.
    if (this.currentStartDate && this.currentStartDate > selectedDate) {
      this.currentStartDate = null;
      this.currentDuration = null;
      this.setStartDateFieldValue(this.currentStartDate);
      this.setDurationFieldValue(this.currentDuration);
      this.doMarkFieldAsTouched('start_date');
    }

    this.currentDueDate = selectedDate;
    this.setDueDateFieldValue(this.currentDueDate);
    this.doMarkFieldAsTouched('due_date');

    this.keepFieldValue();
  }

  private updateFlatpickrCalendar() {
    const dates:Date[] = _.compact([this.currentStartDate, this.currentDueDate]);
    const ignoreNonWorkingDays = this.currentIgnoreNonWorkingDays;
    const mode = this.mode();

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

  private lastClickedDate(changedDates:Date[]):Date|null {
    const flatPickrDates = this.timezone.utcDatesToISODateStrings(changedDates);
    if (flatPickrDates.length === 1) {
      return this.toDate(flatPickrDates[0]);
    }

    const fieldDates = _.compact([this.currentStartDate, this.currentDueDate])
                        .map((date) => this.timezone.utcDateToISODateString(date));
    const diff = _.difference(flatPickrDates, fieldDates);
    return this.toDate(diff[0]);
  }

  setStartDateFieldValue(date:Date|null) {
    const field = document.getElementById('work_package_start_date') as HTMLInputElement;
    if (field) {
      field.value = this.datetoIso(date);
    }
  }

  setDueDateFieldValue(date:Date|null) {
    const field = document.getElementById('work_package_due_date') as HTMLInputElement;
    if (field) {
      field.value = this.datetoIso(date);
    }
  }

  setDurationFieldValue(duration:number|null) {
    const field = document.getElementById('work_package_duration') as HTMLInputElement;
    if (field) {
      field.value = duration?.toString() ?? '';
    }
  }

  doMarkFieldAsTouched(fieldName:string) {
    super.doMarkFieldAsTouched(fieldName);

    this.keepFieldValue();
  }

  setIgnoreNonWorkingDays(event:{ target:HTMLInputElement }) {
    this.currentIgnoreNonWorkingDays = !event.target.checked;
    this.updateFlatpickrCalendar();
  }

  afterRendering(params:{ shouldFocusBanner?:boolean }) {
    if (params.shouldFocusBanner) {
      this.focusOnOpen();
    }
    this.readCurrentValues();
    this.updateFlatpickrCalendar();
  }

  // Must be true for duration field to avoid modifying the value while the user
  // is typing or pressing backspace.
  // Must be false for start and finish date fields to allow value to be
  // corrected if the date is invalid (non-working day for instance).
  ignoreActiveValueWhenMorphing():boolean {
    return document.activeElement?.id === 'work_package_duration';
  }

  readInitialValues() {
    this.fieldInputTargets.forEach((inputField) => {
      this.assignReadValues(inputField);
    });
  }

  readCurrentValues() {
    const fieldNames = ['ignore_non_working_days', 'start_date', 'due_date', 'duration'];
    fieldNames.forEach((name:string) => {
      const field = document.getElementById(`work_package_${name}`);
      if (field) {
        this.assignReadValues(field as HTMLInputElement);
      }
    });
  }

  private assignReadValues(inputField:HTMLInputElement) {
    if (inputField.name === 'work_package[ignore_non_working_days]') {
      // field is "Working days only",  but has the name "work_package[ignore_non_working_days]" for form submission.
      // Submits "0" if checked, and "1" if not checked thanks to a hidden field with same name.
      this.currentIgnoreNonWorkingDays = !inputField.checked;
    } else if (inputField.name === 'work_package[start_date]') {
      this.currentStartDate = this.toDate(inputField.value);
    } else if (inputField.name === 'work_package[due_date]') {
      this.currentDueDate = this.toDate(inputField.value);
      this.isMilestone = false;
    } else if (inputField.name === 'work_package[duration]') {
      this.currentDuration = this.toDuration(inputField.value);
    }

    if (inputField.classList.contains('op-datepicker-modal--date-field_current')) {
      this.highlightedField = inputField;
    }
  }

  // called from inputs defined in the date_picker/date_form_component.rb
  onHighlightField(e:Event) {
    const fieldToHighlight = e.target as HTMLInputElement;
    if (fieldToHighlight) {
      this.highlightField(fieldToHighlight);
      window.setTimeout(() => {
        // For mobile, we have to make sure that the active field is scrolled into view after the keyboard is opened
        fieldToHighlight.scrollIntoView(true);
      }, 300);
      // Datepicker can need an update when the focused field changes. This
      // allows to switch between single and range mode in certain edge cases.
      this.readCurrentValues();
      this.updateFlatpickrCalendar();
    }
  }

  highlightField(newHighlightedField:HTMLInputElement|undefined) {
    if (newHighlightedField === undefined) {
      return;
    }

    this.highlightedField = newHighlightedField;
    Array.from(document.getElementsByClassName('op-datepicker-modal--date-field_current')).forEach(
      (el) => {
        el.classList.remove('op-datepicker-modal--date-field_current');
        el.removeAttribute('data-qa-highlighted');
      },
    );

    this.highlightedField.classList.add('op-datepicker-modal--date-field_current');
    this.highlightedField.dataset.qaHighlighted = 'true';
  }

  private mode():'single'|'range' {
    if (this.isMilestone) {
      return 'single';
    }

    // This is a very special case in which only one date is set, and we want to
    // modify exactly that date again because it is highlighted. Then it does
    // not make sense to display a range as we are only changing one date.
    if ((this.highlightedField?.name === 'work_package[start_date]' && !this.currentDueDate)
      || (this.highlightedField?.name === 'work_package[due_date]' && !this.currentStartDate)) {
      return 'single';
    }

    return 'range';
  }

  setTodayForField(event:unknown) {
    (event as Event).preventDefault();

    const targetFieldID = (event as { params:{ fieldReference:string } }).params.fieldReference;
    if (targetFieldID) {
      const inputField = document.getElementById(targetFieldID);
      if (inputField) {
        (inputField as HTMLInputElement).value = this.timezone.utcDateToISODateString(new Date(Date.now()));
        inputField.dispatchEvent(new Event('input'));
      }
    }
  }

  private datetoIso(date:Date|null):string {
    if (date) {
      return this.timezone.utcDateToISODateString(date);
    }
    return '';
  }

  private toDate(date:string|null):Date|null {
    if (date) {
      return new Date(date);
    }
    return null;
  }

  private toDuration(duration:string|null):number|null {
    if (duration) {
      return parseInt(duration, 10);
    }
    return null;
  }

  /*
  * I am aware, that the following methods look pretty similar to the logic on the progress/preview controller.
  * There are however slight differences. That could still be abstracted into the shared parent controller.
  * However, this comes at the cost of heavily reduced readability which is why it was agreed to keep it duplicated like this.
  * Further, in the future, is is likely that the datepicker and the progress will further diverge in their behavior.
  */
  private keepFieldValue() {
    if (this.isInitialValueEmpty('start_date') && !this.isTouched('start_date')) {
      // let start date be derived
      return;
    }

    if (this.isBeingEdited('start_date')) {
      this.untouchFieldsWhenStartDateIsEdited();
    } else if (this.isBeingEdited('due_date')) {
      this.untouchFieldsWhenDueDateIsEdited();
    } else if (this.isBeingEdited('duration')) {
      this.untouchFieldsWhenDurationIsEdited();
    } else if (this.isBeingEdited('ignore_non_working_days')) {
      this.untouchFieldsWhenIgnoreNonWorkingDaysIsEdited();
    }
  }

  private untouchFieldsWhenStartDateIsEdited() {
    if (this.areBothTouched('due_date', 'duration')) {
      if (this.isValueEmpty('duration') && this.isValueEmpty('due_date')) {
        return;
      }
      if (this.isValueEmpty('duration')) {
        this.markUntouched('duration');
      } else {
        this.markUntouched('due_date');
      }
    } else if (this.isTouchedAndEmpty('due_date') && this.isValueSet('duration')) {
      // force due date derivation
      this.markUntouched('due_date');
      this.markTouched('duration');
    } else if (this.isTouchedAndEmpty('duration') && this.isValueSet('due_date')) {
      // force duration derivation
      this.markUntouched('duration');
      this.markTouched('due_date');
    }
  }

  private untouchFieldsWhenDueDateIsEdited():void {
    if (this.scheduleManuallyValue) {
      if (this.isTouchedAndEmpty('start_date') && this.isValueSet('duration')) {
        // force start date derivation
        this.markUntouched('start_date');
        this.markTouched('duration');
      } else if (this.isValueSet('start_date')) {
        this.markUntouched('duration');
      }
    } else {
      this.markUntouched('duration');
    }
  }

  private untouchFieldsWhenDurationIsEdited():void {
    if (this.scheduleManuallyValue) {
      if (this.isTouched('start_date')) {
        if (this.isValueSet('start_date')) {
          this.markUntouched('due_date');
        } else if (this.isValueSet('due_date')) {
          this.markUntouched('start_date');
          this.markTouched('due_date');
        }
      } else if (this.isTouched('due_date')) {
        if (this.isValueSet('due_date')) {
          this.markUntouched('start_date');
        } else if (this.isValueSet('start_date')) {
          this.markUntouched('due_date');
          this.markTouched('start_date');
        }
      }
    } else {
      this.markUntouched('due_date');
    }
  }

  private untouchFieldsWhenIgnoreNonWorkingDaysIsEdited():void {
    if (!this.scheduleManuallyValue) {
      if (this.isTouched('duration')) {
        this.markUntouched('due_date');
      } else if (this.isTouched('due_date')) {
        this.markUntouched('duration');
      }
    }
  }

  private focusOnOpen() {
    const banner = document.querySelector<HTMLElement>('.wp-datepicker--banner');
    if (banner) {
      banner.setAttribute('tabindex', '-1');
      banner.focus();
    } else {
      const tabs = document.querySelector<HTMLElement>('.wp-datepicker-dialog--UnderlineNav');
      if (tabs) {
        tabs.setAttribute('tabindex', '-1');
        tabs.focus();
      }
    }
  }
}
