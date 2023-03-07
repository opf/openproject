// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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

import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { States } from 'core-app/core/states/states.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import {
  ChangeDetectorRef, Component, ElementRef, Inject, OnInit, resolveForwardRef,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

@Component({
  templateUrl: './query-get-ical-url.modal.html',
  styleUrls: ['./query-get-ical-url.modal.sass']
})
export class QueryGetIcalUrlModalComponent extends OpModalComponent implements OnInit {
  public query:QueryResource;

  public isBusy = false;

  public icalUrl: string;

  public text = {
    label_ical_sharing: 'Share calendar', // TODO: translate 
    description_ical_sharing: 'You can share and import this calendar by using the following iCalendar URL:', // TODO: translate 
    button_copy: 'Copy URL', // TODO: translate
    copy_success_text: 'URL copied to clipboard', // TODO: translate
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title')
  };

  constructor(
    readonly elementRef:ElementRef,
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly I18n:I18nService,
    readonly states:States,
    readonly querySpace:IsolatedQuerySpace,
    readonly cdRef:ChangeDetectorRef,
    readonly wpListService:WorkPackagesListService,
    readonly halNotification:HalResourceNotificationService,
    readonly toastService:ToastService,
    protected apiV3Service:ApiV3Service
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit():void {
    super.ngOnInit();

    this.query = this.querySpace.query.value!;

    this.isBusy = true;

    this
      .query
      .shareCalendars()
      .then((response:HalResource) => {
        this.icalUrl = response.icalUrl;
        this.isBusy = false;
        this.cdRef.detectChanges(); 
        // or would that be better?
        // this.ngZone.run(() => {
        //   this.icalUrl = response.icalUrl;
        //   this.isBusy = false;
        // });
      })
  }

  public copyUrl($event:Event):void {
    if (this.isBusy) {
      return;
    }

    navigator.clipboard.writeText(this.icalUrl)
      .then(() => {
        this.toastService.addSuccess(this.text.copy_success_text);
      })

  }
}
