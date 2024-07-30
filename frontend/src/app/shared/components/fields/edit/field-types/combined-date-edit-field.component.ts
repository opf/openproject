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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Component } from '@angular/core';
import { DatePickerEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/date-picker-edit-field.component';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Component({
  templateUrl: './combined-date-edit-field.component.html',
})
export class CombinedDateEditFieldComponent extends DatePickerEditFieldComponent {
  dates = '';

  opened = false;

  text = {
    placeholder: {
      startDate: this.I18n.t('js.label_no_start_date'),
      dueDate: this.I18n.t('js.label_no_due_date'),
      date: this.I18n.t('js.label_no_date'),
    },
  };

  get isMultiDate():boolean {
    return !this.change.schema.isMilestone;
  }

  public onInputClick(event:MouseEvent) {
    event.stopPropagation();
  }

  public showDatePickerModal():void {
    this.opened = true;
  }

  public onModalClosed():void {
    this.opened = false;

    if (!this.handler.inEditMode) {
      this.handler.deactivate(false);
    }
    this.resetDates();
  }

  public save():void {
    this.handler.handleUserSubmit();
    this.onModalClosed();
  }

  public cancel():void {
    this.handler.reset();
    this.onModalClosed();
  }

  // Overwrite super in order to set the initial dates.
  protected initialize():void {
    super.initialize();
    this.resetDates();
  }

  protected resetDates():void {
    switch (this.name) {
      case 'combinedDate':
        this.dates = `${this.current('startDate')} - ${this.current('dueDate')}`;
        break;

      case 'startDate':
        this.dates = `${this.current('startDate')}`;
        break;

      case 'dueDate':
        this.dates = `${this.current('dueDate')}`;
        break;

      case 'date':
        this.dates = `${this.current('date')}`;
        break;

      default:
        break;
    }
  }

  protected current(dateAttribute:'startDate' | 'dueDate' | 'date'):string {
    const value = (this.resource && (this.resource as WorkPackageResource)[dateAttribute]) as string|null;
    return (value || this.text.placeholder[dateAttribute]);
  }
}
