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

import { WorkPackagesListService } from '../../wp-list/wp-list.service';
import { States } from '../../states.service';
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";
import { QueryResource } from 'core-app/modules/hal/resources/query-resource';
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { OpModalComponent } from "core-app/modules/modal/modal.component";
import { OpModalLocalsToken } from "core-app/modules/modal/modal.service";
import { OpModalLocalsMap } from "core-app/modules/modal/modal.types";
import { ChangeDetectorRef, Component, ElementRef, Inject, OnInit } from "@angular/core";
import { QuerySharingChange } from "core-components/modals/share-modal/query-sharing-form.component";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";

@Component({
  templateUrl: './query-sharing.modal.html'
})
export class QuerySharingModal extends OpModalComponent implements OnInit {
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
    close_popup: this.I18n.t('js.close_popup_title')
  };

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly I18n:I18nService,
              readonly states:States,
              readonly querySpace:IsolatedQuerySpace,
              readonly cdRef:ChangeDetectorRef,
              readonly wpListService:WorkPackagesListService,
              readonly halNotification:HalResourceNotificationService,
              readonly notificationsService:NotificationsService) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();

    this.query = this.querySpace.query.value!;

    this.isStarred = this.query.starred;
    this.isPublic = this.query.public;
  }


  public setValues(change:QuerySharingChange) {
    this.isStarred = change.isStarred;
    this.isPublic = change.isPublic;
  }

  public get afterFocusOn() {
    return jQuery('#work-packages-settings-button');
  }

  public saveQuery($event:JQuery.TriggeredEvent) {
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
        this.notificationsService.addError(this.I18n.t('js.errors.query_saving'));
        this.isBusy = false;
      });
  }
}
