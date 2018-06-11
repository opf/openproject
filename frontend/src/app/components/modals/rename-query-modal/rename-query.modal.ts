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

import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackagesListService} from '../../wp-list/wp-list.service';
import {States} from '../../states.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {OpModalComponent} from "core-components/op-modals/op-modal.component";
import {Component, ElementRef, Inject, OnInit, ViewChild} from "@angular/core";
import {OpModalLocalsToken} from "core-components/op-modals/op-modal.service";
import {OpModalLocalsMap} from "core-components/op-modals/op-modal.types";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  templateUrl: './rename-query.modal.html'
})
export class RenameQueryModal extends OpModalComponent implements OnInit {
  public queryName:string = '';
  public isBusy = false;

  @ViewChild('queryNameField') queryNameField:ElementRef;

  public text = {
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
              readonly I18n:I18nService,
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

  public get currentQuery():QueryResource {
    return this.states.query.resource.value!;
  }

  public get afterFocusOn() {
    return jQuery('#work-packages-settings-button');
  }

  public updateQuery($event:JQueryEventObject) {
    const query = this.currentQuery;
    this.isBusy = true;
    query.name = this.queryName;

    this.wpListService.save(query)
      .then(() => {
        this.closeMe($event);
      })
      .catch((error) => this.wpNotificationsService.handleErrorResponse(error))
      .then(() => this.isBusy = false);
  };
}
