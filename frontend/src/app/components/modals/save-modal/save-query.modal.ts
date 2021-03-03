//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { ChangeDetectorRef, Component, ElementRef, Inject, ViewChild } from "@angular/core";
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";
import { QueryResource } from 'core-app/modules/hal/resources/query-resource';
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { OpModalComponent } from "core-app/modules/modal/modal.component";
import { OpModalLocalsToken } from "core-app/modules/modal/modal.service";
import { OpModalLocalsMap } from "core-app/modules/modal/modal.types";
import { QuerySharingChange } from "core-components/modals/share-modal/query-sharing-form.component";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { WorkPackagesListService } from "core-components/wp-list/wp-list.service";
import { States } from '../../states.service';

@Component({
  templateUrl: './save-query.modal.html'
})
export class SaveQueryModal extends OpModalComponent {
  public queryName = '';
  public isStarred = false;
  public isPublic = false;
  public isBusy = false;

  @ViewChild('queryNameField', { static: true }) queryNameField:ElementRef;

  public text = {
    title: this.I18n.t('js.modals.form_submit.title'),
    text: this.I18n.t('js.modals.form_submit.text'),
    save_as: this.I18n.t('js.label_save_as'),
    label_name: this.I18n.t('js.modals.label_name'),
    label_visibility_settings: this.I18n.t('js.label_visibility_settings'),
    button_save: this.I18n.t('js.modals.button_save'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title')
  };

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly I18n:I18nService,
              readonly states:States,
              readonly querySpace:IsolatedQuerySpace,
              readonly wpListService:WorkPackagesListService,
              readonly halNotification:HalResourceNotificationService,
              readonly cdRef:ChangeDetectorRef,
              readonly notificationsService:NotificationsService) {
    super(locals, cdRef, elementRef);
  }

  public setValues(change:QuerySharingChange) {
    this.isStarred = change.isStarred;
    this.isPublic = change.isPublic;
  }

  public onOpen() {
    this.queryNameField.nativeElement.focus();
  }

  public get afterFocusOn() {
    return jQuery('#work-packages-settings-button');
  }

  public saveQueryAs($event:JQuery.TriggeredEvent) {
    if (this.isBusy || !this.queryName) {
      return;
    }

    this.isBusy = true;
    const query = this.querySpace.query.value!;
    query.public = this.isPublic;

    this.wpListService
      .create(query, this.queryName)
      .then((savedQuery:QueryResource):Promise<any> => {
        if (this.isStarred && !savedQuery.starred) {
          return this.wpListService.toggleStarred(savedQuery).then(() => this.closeMe($event));
        }

        this.closeMe($event);
        return Promise.resolve(true);
      })
      .catch((error:any) => this.halNotification.handleRawError(error))
      .then(() => this.isBusy = false); // Same as .finally()
  }
}
