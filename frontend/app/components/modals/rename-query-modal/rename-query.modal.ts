//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {WorkPackagesListService} from '../../wp-list/wp-list.service';
import {States} from '../../states.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {NotificationsService} from "core-components/common/notifications/notifications.service";
import {OpModalComponent} from "core-components/op-modals/op-modal.component";
import {Component, ElementRef, Inject, OnInit, ViewChild} from "@angular/core";
import {I18nToken, OpModalLocalsToken} from "core-app/angular4-transition-utils";
import {OpModalLocalsMap} from "core-components/op-modals/op-modal.types";
import {QuerySharingChange} from "core-components/modals/share-modal/query-sharing-form.component";

@Component({
  template: require('!!raw-loader!./rename-query.modal.html')
})
export class RenameQueryModal extends OpModalComponent implements OnInit {
  public queryName:string = '';

  @ViewChild('queryNameField') queryNameField:ElementRef;

  public text:{ [key:string]:string } = {
    title: this.I18n.t('js.modals.label_settings'),
    text: this.I18n.t('js.modals.form_submit.text'),
    save_as: this.I18n.t('js.label_save_as'),
    label_name: this.I18n.t('js.modals.label_name'),
    button_submit: this.I18n.t('js.modals.button_submit'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title')
  };

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              @Inject(I18nToken) readonly I18n:op.I18n,
              readonly states:States,
              readonly wpListService:WorkPackagesListService,
              readonly wpNotificationsService:WorkPackageNotificationService,
              readonly notificationsService:NotificationsService) {
    super(locals, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();
    this.queryName = this.currentQuery.name;
  }

  public onOpen() {
    this.queryNameField.nativeElement.focus();
  }

  public get currentQuery() {
    return this.states.query.resource.value!;
  }

  public get afterFocusOn() {
    return jQuery('#work-packages-settings-button');
  }

  public updateQuery($event:JQueryEventObject) {
    const query = this.currentQuery;
    query.name = this.queryName;

    this.wpListService.save(query)
      .then(() => {
        this.closeMe($event);
      })
      .catch((error) => this.wpNotificationsService.handleRawError(error));
  };
}
