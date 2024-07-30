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

import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { States } from 'core-app/core/states/states.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import {
  ChangeDetectorRef, Component, ElementRef, Inject, OnInit,
} from '@angular/core';
import { QuerySharingChange } from 'core-app/shared/components/modals/share-modal/query-sharing-form.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';

@Component({
  templateUrl: './query-sharing.modal.html',
})
export class QuerySharingModalComponent extends OpModalComponent implements OnInit {
  public query:QueryResource;

  public isStarred = false;

  public isPublic = false;

  public isBusy = false;

  public text = {
    title: this.I18n.t('js.modals.form_submit.title'),
    text: this.I18n.t('js.modals.form_submit.text'),
    save_as: this.I18n.t('js.label_save_as'),
    label_name: this.I18n.t('js.modals.label_name'),
    label_visibility_settings: this.I18n.t('js.label_visibility_settings'),
    button_save: this.I18n.t('js.modals.button_save'),
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
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit():void {
    super.ngOnInit();

    this.query = this.querySpace.query.value!;

    this.isStarred = this.query.starred;
    this.isPublic = this.query.public;
  }

  public setValues(change:QuerySharingChange):void {
    this.isStarred = change.isStarred;
    this.isPublic = change.isPublic;
  }

  public get afterFocusOn():HTMLElement {
    return document.getElementById('work-packages-settings-button') as HTMLElement;
  }

  public saveQuery($event:Event):void {
    if (this.isBusy) {
      return;
    }

    this.isBusy = true;
    const promises = [];

    if (this.query.public !== this.isPublic) {
      this.query.public = this.isPublic;

      promises.push(this.wpListService.save(this.query));
    }

    if (this.query.starred !== this.isStarred) {
      promises.push(this.wpListService.toggleStarred(this.query));
    }

    Promise
      .all(promises)
      .then(() => {
        this.closeMe($event);
        this.isBusy = false;
      })
      .catch(() => {
        this.toastService.addError(this.I18n.t('js.error.query_saving'));
        this.isBusy = false;
      });
  }
}
