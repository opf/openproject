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

import { Component, ElementRef, OnInit } from "@angular/core";
import { I18nService } from "app/modules/common/i18n/i18n.service";
import { EnterpriseTrialService } from "app/components/enterprise/enterprise-trial.service";
import { HttpClient } from "@angular/common/http";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";
import { distinctUntilChanged } from "rxjs/operators";
import { TimezoneService } from "core-components/datetime/timezone.service";

@Component({
  selector: 'enterprise-trial-waiting',
  templateUrl: './ee-trial-waiting.component.html',
  styleUrls: ['./ee-trial-waiting.component.sass']
})
export class EETrialWaitingComponent implements OnInit {
  created = this.timezoneService.formattedDate(new Date().toString());
  email = '';

  public text = {
    confirmation_info: (date:string, email:string) => this.I18n.t('js.admin.enterprise.trial.confirmation_info',{
      date: date,
      email: email
    }),
    resend: this.I18n.t('js.admin.enterprise.trial.resend_link'),
    resend_success: this.I18n.t('js.admin.enterprise.trial.resend_success'),
    resend_warning: this.I18n.t('js.admin.enterprise.trial.resend_warning'),
    session_timeout: this.I18n.t('js.admin.enterprise.trial.session_timeout'),
    status_confirmed: this.I18n.t('js.admin.enterprise.trial.status_confirmed'),
    status_label: this.I18n.t('js.admin.enterprise.trial.status_label'),
    status_waiting: this.I18n.t('js.admin.enterprise.trial.status_waiting')
  };

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              protected http:HttpClient,
              protected notificationsService:NotificationsService,
              public eeTrialService:EnterpriseTrialService,
              readonly timezoneService:TimezoneService) {
  }

  ngOnInit() {
    const eeTrialKey = (window as any).gon.ee_trial_key;
    if (eeTrialKey) {
      const savedDateStr = eeTrialKey.created.split(' ')[0];
      this.created = this.timezoneService.formattedDate(savedDateStr);
    }

    this.eeTrialService.userData$
      .values$()
      .pipe(
        distinctUntilChanged(),
      )
      .subscribe(userForm => {
        this.email = userForm.email;
      });
  }

  // resend mail if resend link has been clicked
  public resendMail() {
    this.eeTrialService.cancelled = false;
    this.http.post(this.eeTrialService.resendLink, {})
      .toPromise()
      .then(() => {
        this.notificationsService.addSuccess(this.text.resend_success);
        this.eeTrialService.retryConfirmation();
      })
      .catch(() => {
        if (this.eeTrialService.trialLink) {
          // Check whether the mail has been confirmed by now
          this.eeTrialService.getToken();
        } else {
          this.notificationsService.addError(this.text.resend_warning);
        }
      });
  }
}

