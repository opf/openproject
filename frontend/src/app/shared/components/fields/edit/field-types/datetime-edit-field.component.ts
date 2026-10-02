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

import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import moment from 'moment-timezone';
import { EditFieldComponent } from 'core-app/shared/components/fields/edit/edit-field.component';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

const DATETIME_LOCAL_INPUT_FORMAT = 'YYYY-MM-DDTHH:mm';

@Component({
  template: `
    <input type="datetime-local"
           class="inline-edit--field op-input"
           [attr.aria-required]="required"
           [attr.required]="required"
           [disabled]="inFlight"
           [(ngModel)]="value"
           (keydown)="handleKeydown($event)"
           [id]="handler.htmlId" />
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class DateTimeEditFieldComponent extends EditFieldComponent {
  readonly timezoneService = inject(TimezoneService);

  public get value():string {
    const current = this.datetimeResource[this.name];

    if (!current) {
      return '';
    }

    return this.timezoneService.parseDatetime(current).format(DATETIME_LOCAL_INPUT_FORMAT);
  }

  public set value(input:string) {
    this.datetimeResource[this.name] = this.parseValue(input);
  }

  // Chrome does not submit the surrounding form on Enter in a datetime-local input.
  public handleKeydown(event:KeyboardEvent):void {
    if (event.key === 'Enter' && !this.handler.inEditMode) {
      event.preventDefault();
      void this.handler.handleUserSubmit();
      return;
    }

    void this.handler.handleUserKeydown(event);
  }

  private get datetimeResource():Record<string, string|null|undefined> {
    return this.resource as Record<string, string|null|undefined>;
  }

  protected parseValue(input:string):string|null {
    if (!input) {
      return null;
    }

    const local = moment.tz(input, DATETIME_LOCAL_INPUT_FORMAT, true, this.timezoneService.userTimezone());

    return local.isValid() ? local.utc().format() : null;
  }
}
