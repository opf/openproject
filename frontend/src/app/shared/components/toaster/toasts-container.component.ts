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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { IToast, ToastService } from './toast.service';


@Component({
  template: `
    <div class="op-toast--wrapper">
      <div class="op-toast--casing">
        <op-toast [toast]="toast" *ngFor="let toast of stack"></op-toast>
      </div>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'opce-toasts-container',
})
export class ToastsContainerComponent extends UntilDestroyedMixin implements OnInit {
  public stack:IToast[] = [];

  constructor(
    readonly toastService:ToastService,
    readonly cdRef:ChangeDetectorRef,
  ) {
    super();
  }

  ngOnInit():void {
    this.toastService
      .current
      .values$('Subscribing to changes in the toaster stack')
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((stack) => {
        this.stack = stack;
        this.cdRef.detectChanges();
      });
  }
}
