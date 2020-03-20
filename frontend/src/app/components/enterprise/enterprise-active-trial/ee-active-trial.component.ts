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

import {Component, ElementRef, OnInit} from "@angular/core";
import {I18nService} from "app/modules/common/i18n/i18n.service";
import {EnterpriseTrialService} from "app/components/enterprise/enterprise-trial.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Component({
  selector: 'enterprise-active-trial',
  templateUrl: './ee-active-trial.component.html',
  styleUrls: ['./ee-active-trial.component.sass']
})
export class EEActiveTrialComponent implements OnInit {
  public text = {
    label_email: this.I18n.t('js.admin.enterprise.trial.form.label_email'),
    label_expires_at: this.I18n.t('js.admin.enterprise.trial.form.label_expires_at'),
    label_maximum_users: this.I18n.t('js.admin.enterprise.trial.form.label_maximum_users'),
    label_starts_at: this.I18n.t('js.admin.enterprise.trial.form.label_starts_at'),
    label_subscriber: this.I18n.t('js.admin.enterprise.trial.form.label_subscriber')
  };
  public subscriber = this.elementRef.nativeElement.dataset['subscriber'];
  public email = this.elementRef.nativeElement.dataset['email'];
  public restrictions = this.elementRef.nativeElement.dataset['restrictions'];
  public startsAt = this.elementRef.nativeElement.dataset['startsAt'];
  public expiresAt = this.elementRef.nativeElement.dataset['expiresAt'];

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              public eeTrialService:EnterpriseTrialService) {
  }

  ngOnInit() {
    // TODO iterate over all restrictions
    console.log('restrictions: ', this.restrictions);
    // trial is not active yet
    if (!this.subscriber) {
      this.subscriber = this.eeTrialService.savedUserData.subscriber;
      this.email =  this.eeTrialService.savedUserData.email;
      this.startsAt = '-';
      this.expiresAt = '-';
    }
  }
}

DynamicBootstrapper.register({
  selector: 'enterprise-active-trial', cls: EEActiveTrialComponent
});

