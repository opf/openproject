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

import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';

import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

interface DatePickerModalResource {
  id:string;
  startDate:string|null;
  dueDate:string|null;
  duration:string|null;
  includeNonWorkingDays:boolean|null;
}

@Component({
  templateUrl: './wp-date-picker.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class OpWpDatePickerModalComponent extends OpModalComponent implements OnInit {
  readonly pathHelper = inject(PathHelperService);

  turboFrameSrc:string;

  showCloseButton = false;

  ngOnInit() {
    super.ngOnInit();
    this.updateFrameSrc();
  }

  public handleSuccessfulCreate(JSONResponse:{ duration:number, startDate:Date, dueDate:Date, includeNonWorkingDays:boolean, scheduleManually:boolean }):void {
    document.dispatchEvent(
      new CustomEvent('date-picker-modal:create', {
        detail: JSONResponse,
      }),
    );

    this.closeModal();
  }

  public handleSuccessfulUpdate():void {
    document.dispatchEvent(new CustomEvent('date-picker-modal:update'));

    this.closeModal();
  }

  public handleCancel():void {
    document.dispatchEvent(new CustomEvent('date-picker-modal:cancel'));

    this.closeModal();
  }

  public closeModal():void {
    this.closeMe();
  }

  public updateFrameSrc():void {
    const resource = this.locals.resource as DatePickerModalResource;
    const url = new URL(
      this.pathHelper.workPackageDatepickerDialogContentPath(resource.id),
      window.location.origin,
    );

    url.searchParams.set('field', this.locals.name as string);
    url.searchParams.set('work_package[initial][start_date]', this.nullAsEmptyStringFormatter(resource.startDate));
    url.searchParams.set('work_package[initial][due_date]', this.nullAsEmptyStringFormatter(resource.dueDate));
    url.searchParams.set('work_package[initial][duration]', this.nullAsEmptyStringFormatter(resource.duration));
    url.searchParams.set('work_package[initial][ignore_non_working_days]', this.nullAsEmptyStringFormatter(resource.includeNonWorkingDays));

    url.searchParams.set('work_package[start_date]', this.nullAsEmptyStringFormatter(resource.startDate));
    url.searchParams.set('work_package[due_date]', this.nullAsEmptyStringFormatter(resource.dueDate));
    url.searchParams.set('work_package[duration]', this.nullAsEmptyStringFormatter(resource.duration));
    url.searchParams.set('work_package[ignore_non_working_days]', this.nullAsEmptyStringFormatter(resource.includeNonWorkingDays));
    if (resource.id === 'new' && resource.startDate) {
      url.searchParams.set('work_package[start_date_touched]', 'true');
    }

    this.turboFrameSrc = url.toString();
  }

  private nullAsEmptyStringFormatter(value:null|undefined|string|boolean):string {
    if (value === undefined || value === null) {
      return '';
    }
    return String(value);
  }
}
