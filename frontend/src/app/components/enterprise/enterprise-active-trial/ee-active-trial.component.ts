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

import {ChangeDetectorRef, Component, ElementRef, OnInit} from "@angular/core";
import {distinctUntilChanged} from "rxjs/operators";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {I18nService} from "app/modules/common/i18n/i18n.service";
import {baseUrlAugur, EnterpriseTrialService} from "app/components/enterprise/enterprise-trial.service";
import {HttpClient, HttpErrorResponse} from "@angular/common/http";

export const enterpriseActiveTrialSelector = 'enterprise-active-trial';

@Component({
  selector: enterpriseActiveTrialSelector,
  templateUrl: './ee-active-trial.component.html',
  styleUrls: ['./ee-active-trial.component.sass']
})
export class EEActiveTrialComponent extends UntilDestroyedMixin implements OnInit {
  public text = {
    label_email: this.I18n.t('js.admin.enterprise.trial.form.label_email'),
    label_expires_at: this.I18n.t('js.admin.enterprise.trial.form.label_expires_at'),
    label_maximum_users: this.I18n.t('js.admin.enterprise.trial.form.label_maximum_users'),
    label_starts_at: this.I18n.t('js.admin.enterprise.trial.form.label_starts_at'),
    label_subscriber: this.I18n.t('js.admin.enterprise.trial.form.label_subscriber')
  };

  public subscriber = this.elementRef.nativeElement.dataset['subscriber'];
  public email = this.elementRef.nativeElement.dataset['email'];
  public userCount = this.elementRef.nativeElement.dataset['userCount'];
  public startsAt = this.elementRef.nativeElement.dataset['startsAt'];
  public expiresAt = this.elementRef.nativeElement.dataset['expiresAt'];

  constructor(readonly elementRef:ElementRef,
              readonly cdRef:ChangeDetectorRef,
              readonly I18n:I18nService,
              protected http:HttpClient,
              public eeTrialService:EnterpriseTrialService) {
    super();
  }

  ngOnInit() {
    if (!this.subscriber) {
      this.eeTrialService.userData$
        .pipe(
          distinctUntilChanged(),
          this.untilDestroyed()
        )
        .subscribe(data => {
          this.subscriber = data.subscriber;
          this.email = data.email;
          this.cdRef.detectChanges();
        });

      this.initialize();
    }
  }

  private initialize():void {
    let eeTrialKey = this.loadGonData();

    if (eeTrialKey && !this.eeTrialService.userData) {
      // after reload: get data from Augur using the trial key saved in gon
      this.eeTrialService.trialLink = baseUrlAugur + '/public/v1/trials/' + eeTrialKey.value;
      this.getUserDataFromAugur();
    }
  }

  // use the trial key saved in the db
  // to get the user data from Augur
  private getUserDataFromAugur() {
    this.http
      .get<any>(this.eeTrialService.trialLink + '/details')
      .toPromise()
      .then((userData:any) => {
        this.subscriber = userData.first_name + ' ' + userData.last_name;
        this.email =  userData.email;
        this.eeTrialService.retryConfirmation();
      })
      .catch((error:HttpErrorResponse) => {
        // Check whether the mail has been confirmed by now
        this.eeTrialService.getToken();
      });
  }

  private loadGonData():{value:string}|undefined {
    let gon = (window as any).gon;
    return gon ? gon.ee_trial_key : undefined;
  }
}
