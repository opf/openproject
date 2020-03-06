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

import {AfterViewInit, ChangeDetectorRef, Component, ElementRef, Inject, Input, ViewChild} from "@angular/core";
import {HttpClient, HttpErrorResponse} from "@angular/common/http";
import {FormBuilder, FormControl, FormGroup, Validators} from "@angular/forms";
import {OpModalComponent} from "app/components/op-modals/op-modal.component";
import {OpModalLocalsToken} from "app/components/op-modals/op-modal.service";
import {OpModalLocalsMap} from "app/components/op-modals/op-modal.types";
import {I18nService} from "app/modules/common/i18n/i18n.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {EETrialFormComponent} from "core-components/enterprise/enterprise-modal/enterprise-trial-form/ee-trial-form.component";
import {EnterpriseTrialService} from "core-components/enterprise/enterprise-trial.service";

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
  selector: 'enterprise-trial-modal',
  templateUrl: './enterprise-trial.modal.html',
  styleUrls: ['./enterprise-trial.modal.sass']
})
export class EnterpriseTrialModal extends OpModalComponent implements AfterViewInit {
  @ViewChild(EETrialFormComponent, { static: false }) formComponent:EETrialFormComponent;
  @Input() public opReferrer:string;

  public trialForm:FormGroup;

  public showClose:boolean;
  public confirmed:boolean;
  public cancelled = false;
  public status:string;
  public errorMsg:string|undefined;

  private options:EnterpriseTrialOptions;

  public text = {
    button_submit: this.I18n.t('js.modals.button_submit'),
    button_cancel: this.I18n.t('js.modals.button_cancel'),
    button_continue: this.I18n.t('js.button_continue'),
    close_popup: this.I18n.t('js.close_popup_title'),
    label_test_ee: this.I18n.t('js.admin.enterprise.trial.test_ee'),
    next_step: this.I18n.t('js.admin.enterprise.trial.next_step'),
    resend: this.I18n.t('js.admin.enterprise.trial.resend_link'),
    title: this.I18n.t('js.modals.form_submit.title'),
    text: this.I18n.t('js.modals.form_submit.text'),
  };

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService,
              protected http:HttpClient,
              readonly pathHelper:PathHelperService,
              protected notificationsService:NotificationsService,
              public eeTrialService:EnterpriseTrialService) {
    super(locals, cdRef, elementRef);

    // modal configuration
    this.options = locals.options || {};
    this.closeOnEscape = _.defaultTo(this.options.closeByEscape, true);
    this.closeOnOutsideClick = _.defaultTo(this.options.closeByDocument, true);
    this.showClose = _.defaultTo(this.options.showClose, true);

    // override default texts if any
    this.text = _.defaults(this.options.text, this.text);
  }

  ngAfterViewInit() {
    this.trialForm = this.formComponent.trialForm;
  }

  // checks if form is valid and submits it
  public onSubmit() {
    if (this.trialForm.valid) {
      this.trialForm.addControl('_type', new FormControl('enterprise-trial'));

      this.eeTrialService.cancelled = false;
      this.eeTrialService.sendForm(this.trialForm.value);
    }
  }

  // TODO: add enterprise onboarding youtube video
  public startEnterpriseTrial() {
    // open onboarding modal
    this.eeTrialService.status = 'startTrial';
  }

  public closeModal(event:any) {
    // cancel all actions (e.g. an already send request)
    this.eeTrialService.cancelled = true;
    this.closeMe(event);
    // refresh page to show enterprise trial
    if (this.eeTrialService.status === 'startTrial' || this.eeTrialService.confirmed) {
      window.location.reload();
    }
  }
}

