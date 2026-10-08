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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, ElementRef, inject, ViewChild } from '@angular/core';
import { EditFieldComponent } from 'core-app/shared/components/fields/edit/edit-field.component';
import { HalResourceEditFieldHandler } from 'core-app/shared/components/fields/edit/field-handler/hal-resource-edit-field-handler';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { isoToLocalDatetime, localDatetimeToISO } from 'core-common/local-datetime';

@Component({
  template: `
    <input #input
           type="datetime-local"
           class="inline-edit--field op-input"
           [attr.aria-required]="required"
           [attr.required]="required"
           [disabled]="inFlight"
           [(ngModel)]="value"
           (keydown.enter)="submit($event)"
           (keydown.escape)="handler.handleUserCancel()"
           [id]="handler.htmlId" />
  `,
  standalone: false,
  // TODO: Switch to OnPush once EditFieldComponent marks itself for check on handler.stateChanged$.
  // Until then, an OnPush field stays disabled after a failed save, as only the portal re-renders.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class DateTimeEditFieldComponent extends EditFieldComponent {
  readonly timezoneService = inject(TimezoneService);

  @ViewChild('input', { static: true }) input:ElementRef<HTMLInputElement>;

  public get value():string {
    return isoToLocalDatetime(this.datetimeResource[this.name], this.timezoneService.userTimezone());
  }

  public set value(value:string) {
    // Typing a day digit by digit passes through valid dates (31 becomes 03 first), which must not be kept.
    this.datetimeResource[this.name] = this.hasInvalidInput
      ? this.pristineValue
      : localDatetimeToISO(value, this.timezoneService.userTimezone());
  }

  public submit(event:Event):void {
    event.preventDefault();

    if (this.hasInvalidInput) {
      this.showInvalidInputError();
      return;
    }

    void this.handler.handleUserSubmit();
  }

  // The browser reports an impossible date like 31.06. as an empty value and only flags it via badInput.
  private get hasInvalidInput():boolean {
    return this.input.nativeElement.validity.badInput;
  }

  private showInvalidInputError():void {
    if (this.handler instanceof HalResourceEditFieldHandler) {
      this.handler.setErrors([this.I18n.t('js.error.invalid_datetime', { field: this.handler.fieldLabel })]);
    }
  }

  private get pristineValue():string|null {
    return (this.change.pristineResource as Record<string, string|null>)[this.name];
  }

  private get datetimeResource():Record<string, string|null> {
    return this.resource as Record<string, string|null>;
  }
}
