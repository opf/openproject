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

import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';

import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

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
    const url = new URL(
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      this.pathHelper.workPackageDatepickerDialogContentPath(this.locals.resource.id as string),
      window.location.origin,
    );

    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
    url.searchParams.set('field', this.locals.name);
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument,@typescript-eslint/no-unsafe-member-access
    url.searchParams.set('work_package[initial][start_date]', this.nullAsEmptyStringFormatter(this.locals.resource.startDate));
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument,@typescript-eslint/no-unsafe-member-access
    url.searchParams.set('work_package[initial][due_date]', this.nullAsEmptyStringFormatter(this.locals.resource.dueDate));
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument,@typescript-eslint/no-unsafe-member-access
    url.searchParams.set('work_package[initial][duration]', this.nullAsEmptyStringFormatter(this.locals.resource.duration));
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-argument
    url.searchParams.set('work_package[initial][ignore_non_working_days]', this.nullAsEmptyStringFormatter(this.locals.resource.includeNonWorkingDays));

    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument,@typescript-eslint/no-unsafe-member-access
    url.searchParams.set('work_package[start_date]', this.nullAsEmptyStringFormatter(this.locals.resource.startDate));
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument,@typescript-eslint/no-unsafe-member-access
    url.searchParams.set('work_package[due_date]', this.nullAsEmptyStringFormatter(this.locals.resource.dueDate));
    // eslint-disable-next-line @typescript-eslint/no-unsafe-argument,@typescript-eslint/no-unsafe-member-access
    url.searchParams.set('work_package[duration]', this.nullAsEmptyStringFormatter(this.locals.resource.duration));
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-argument
    url.searchParams.set('work_package[ignore_non_working_days]', this.nullAsEmptyStringFormatter(this.locals.resource.includeNonWorkingDays));
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    if (this.locals.resource?.id === 'new' && this.locals.resource.startDate) {
      url.searchParams.set('work_package[start_date_touched]', 'true');
    }

    this.turboFrameSrc = url.toString();
  }

  private nullAsEmptyStringFormatter(value:null|undefined|string):string {
    if (value === undefined || value === null) {
      return '';
    }
    return value;
  }
}
