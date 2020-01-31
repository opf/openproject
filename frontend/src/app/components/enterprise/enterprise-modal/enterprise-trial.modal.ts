// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {OpModalComponent} from "app/components/op-modals/op-modal.component";
import {OpModalLocalsToken} from "app/components/op-modals/op-modal.service";
import {ChangeDetectorRef, Component, ElementRef, Inject} from "@angular/core";
import {OpModalLocalsMap} from "app/components/op-modals/op-modal.types";
import {I18nService} from "app/modules/common/i18n/i18n.service";

export interface EnterpriseTrialOptions {
  text:{
    title:string;
    text:string;
    button_continue?:string;
    button_cancel?:string;
  };
  closeByEscape?:boolean;
  showClose?:boolean;
  closeByDocument?:boolean;
}

@Component({
  templateUrl: './enterprise-trial.modal.html'
})
export class EnterpriseTrialModal extends OpModalComponent {

  public showClose:boolean;

  public confirmed = false;

  private options:EnterpriseTrialOptions;

  public text:any = {
    title: this.I18n.t('js.modals.form_submit.title'),
    text: this.I18n.t('js.modals.form_submit.text'),
    button_submit: this.I18n.t('js.modals.button_submit'),
    button_cancel: this.I18n.t('js.modals.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title'),
    label_test_ee: this.I18n.t('js.admin.enterprise.test_ee'),
    label_company: this.I18n.t('js.admin.enterprise.label_company'),
    label_first_name: this.I18n.t('js.admin.enterprise.label_first_name'),
    label_last_name: this.I18n.t('js.admin.enterprise.label_last_name'),
    label_email: this.I18n.t('js.admin.enterprise.label_email'),
    label_domain: this.I18n.t('js.admin.enterprise.label_domain'),
    next_step: this.I18n.t('js.admin.enterprise.next_step')
  };

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService) {

    super(locals, cdRef, elementRef);

    this.options = locals.options || {};
    this.closeOnEscape = _.defaultTo(this.options.closeByEscape, true);
    this.closeOnOutsideClick = _.defaultTo(this.options.closeByDocument, true);
    this.showClose = _.defaultTo(this.options.showClose, true);

    // override default texts if any
    this.text = _.defaults(this.options.text, this.text);
  }

  public submit(evt:JQuery.TriggeredEvent) {
    // open next window
    // this.confirmMailAddress();
    // waiting -> show status and btn "Check status"
    // confirmed -> show confirmed, enable btn "Continue"
    // onclick of continue: this.closeMe(evt);
  }

  public confirmMailAddress() {
    this.confirmed = true;
  }
}

