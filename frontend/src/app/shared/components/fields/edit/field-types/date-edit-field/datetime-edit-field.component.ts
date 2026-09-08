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

import { ChangeDetectionStrategy, Component } from '@angular/core';
import moment from 'moment';
import { DateEditFieldComponent } from 'core-app/shared/components/fields/edit/field-types/date-edit-field/date-edit-field.component';

@Component({
  template: `
    <op-basic-single-datetime-picker [(ngModel)]="value"
      (keydown.escape)="onCancel()"
      (keydown.enter)="handler.handleUserSubmit()"
      (picked)="handler.handleUserSubmit()"
      class="inline-edit--field"
      [id]="handler.htmlId"
      [required]="required"
      [disabled]="inFlight"
      [opAutofocus]="autofocus"
     />
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class DateTimeEditFieldComponent extends DateEditFieldComponent {
  public override parseValue(data:string):string|null {
    return this.validOrNull(data);
  }

  public override formatter(data:string):string|null {
    return this.validOrNull(data);
  }

  private validOrNull(data:string):string|null {
    if (moment(data, moment.ISO_8601, true).isValid()) {
      return data;
    }
    return null;
  }
}
