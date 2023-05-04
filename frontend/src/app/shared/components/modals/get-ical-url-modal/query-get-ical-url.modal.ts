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
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Inject, OnInit, ViewChild
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { timeout } from 'rxjs/operators';

@Component({
  templateUrl: './query-get-ical-url.modal.html',
  styleUrls: ['./query-get-ical-url.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class QueryGetIcalUrlModalComponent extends OpModalComponent implements OnInit {
  public tokenName = '';

  public query:QueryResource;

  public isBusy = false;

  public hasErrors = false;


  @ViewChild('tokenNameField', { static: true }) tokenNameField:ElementRef;

  public text = {
    label_ical_sharing: this.I18n.t('js.ical_sharing_modal.title'),
    description_ical_sharing: this.I18n.t('js.ical_sharing_modal.description'),
    ical_sharing_warning: this.I18n.t('js.ical_sharing_modal.warning'),
    token_name: this.I18n.t('js.ical_sharing_modal.token_name_label'),
    token_name_placeholder: this.I18n.t('js.ical_sharing_modal.token_name_placeholder'),
    token_name_description_text: this.I18n.t('js.ical_sharing_modal.token_name_description_text'),
    token_name_already_in_use_error_text: this.I18n.t('js.ical_sharing_modal.token_name_already_in_use_error_text'),
    button_copy: this.I18n.t('js.ical_sharing_modal.copy_url_label'),
    copy_success_text: this.I18n.t('js.ical_sharing_modal.copy_url_success_text'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title'),
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
    protected apiV3Service:ApiV3Service,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit():void {
    super.ngOnInit();

    this.query = this.querySpace.query.value!;

    // TODO: I'm not sure if this is an error we actually need to catch
    if (!this.query) {
      this.toastService.addError(
      this.I18n.t('js.ical_sharing_modal.inital_setup_error_message')
      );
      // without timeout the modal backdrop is not removed
      setTimeout(() => {
        this.closeMe();
      }, 10);
    }
  }

  public onOpen():void {
    this.tokenNameField.nativeElement.focus();
  }

  public copyUrlAndCloseModal(url:string):void {
    void navigator.clipboard.writeText(url)
      .then(() => {
        this.toastService.addSuccess(this.text.copy_success_text);
        this.closeMe();
      })
      .catch(() => {
        // e.g. browser permission errors
        this.toastService.addError(
          url + " " + this.I18n.t('js.ical_sharing_modal.copy_url_error_text')
        );
      });
  }
  
  public generateAndCopyUrl(event:any):void {
    if (this.isBusy) {
      return;
    }

    let icalUrl = "";

    this.isBusy = true;

    const promise = this
      .apiV3Service
      .queries
      .getIcalUrl(this.query, this.tokenName);

    void promise
      .then((response:HalResource) => {
        icalUrl = String(response.icalUrl.href);
        this.copyUrlAndCloseModal(icalUrl);
      })
      .catch((error:any) => {
        this.halNotification.handleRawError(error)

        this.hasErrors = true

        const el = this.tokenNameField.nativeElement;
        el.classList.add('-error'); //TODO: find default error styling approach

        this.cdRef.detectChanges();
      })
      .then(() => this.isBusy = false); // Same as .finally()
  }
}
