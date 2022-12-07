/*
 *  OpenProject is an open source project management software.
 *  Copyright (C) 2010-2022 the OpenProject GmbH
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License version 3.
 *
 *  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 *  Copyright (C) 2006-2013 Jean-Philippe Lang
 *  Copyright (C) 2010-2013 the ChiliProject Team
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 *  See COPYRIGHT and LICENSE files for more details.
 */

import {
  Directive,
  OnDestroy,
  OnInit,
} from '@angular/core';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { take } from 'rxjs/operators';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { EditFieldComponent } from 'core-app/shared/components/fields/edit/edit-field.component';
import { SingleDateModalComponent } from 'core-app/shared/components/datepicker/single-date-modal/single-date.modal';
import { MultiDateModalComponent } from 'core-app/shared/components/datepicker/multi-date-modal/multi-date.modal';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { DeviceService } from 'core-app/core/browser/device.service';

@Directive()
export abstract class DatePickerEditFieldComponent extends EditFieldComponent implements OnInit, OnDestroy {
  @InjectField() readonly timezoneService:TimezoneService;

  @InjectField() opModalService:OpModalService;

  @InjectField() deviceService:DeviceService;

  protected modal:SingleDateModalComponent|MultiDateModalComponent|null = null;

  ngOnInit():void {
    super.ngOnInit();

    this.handler
      .$onUserActivate
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe(() => {
        this.showDatePickerModal();
      });
  }

  ngOnDestroy():void {
    super.ngOnDestroy();
    this.modal?.closeMe();
  }

  public showDatePickerModal():void {
    const component = this.change.schema.isMilestone ? SingleDateModalComponent : MultiDateModalComponent;
    this.opModalService.show<SingleDateModalComponent|MultiDateModalComponent>(
      component,
      this.injector,
      { changeset: this.change, fieldName: this.name },
      !this.deviceService.isMobile,
    ).subscribe((modal) => {
      this.modal = modal;

      setTimeout(() => {
        const modalElement = jQuery(modal.elementRef.nativeElement).find('.op-datepicker-modal');
        const field = jQuery(this.elementRef.nativeElement);
        modal.reposition(modalElement, field);
      });

      (modal as OpModalComponent)
        .closingEvent
        .pipe(take(1))
        .subscribe(() => {
          this.modal = null;
          this.onModalClosed();
        });
    });
  }

  protected onModalClosed():void {
    void this.handler.handleUserSubmit();
  }
}
