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

import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { EditFieldComponent } from 'core-app/shared/components/fields/edit/edit-field.component';

@Component({
  template: `
    <op-basic-single-datetime-picker [(ngModel)]="value"
      (keydown.escape)="handler.handleUserCancel()"
      (keydown.enter)="handler.handleUserSubmit()"
      (picked)="handler.handleUserSubmit()"
      class="inline-edit--field"
      [id]="handler.htmlId"
      [required]="required"
      [disabled]="inFlight"
      [opAutofocus]="autofocus"
     />
  `,
  standalone: false,
  // TODO: Switch to OnPush once EditFieldComponent marks itself for check on handler.stateChanged$.
  // Until then, an OnPush field stays disabled after a failed save, as only the portal re-renders.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class DateTimeEditFieldComponent extends EditFieldComponent implements OnInit {
  autofocus = false;

  ngOnInit():void {
    super.ngOnInit();
    this.autofocus = !this.handler.inEditMode;
  }

  public get value():string {
    return this.datetimeResource[this.name] ?? '';
  }

  public set value(value:string) {
    this.datetimeResource[this.name] = value || null;
  }

  private get datetimeResource():Record<string, string|null> {
    return this.resource as Record<string, string|null>;
  }
}
