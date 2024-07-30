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

import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
} from '@angular/core';
import {
  UntypedFormBuilder,
  Validators,
} from '@angular/forms';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { EnterpriseTrialService } from 'core-app/features/enterprise/enterprise-trial.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { localizeLink } from 'core-app/shared/helpers/i18n/localized-link';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { IEnterpriseData } from 'core-app/features/enterprise/enterprise-trial.model';

const newsletterURL = 'https://www.openproject.org/newsletter/';

@Component({
  selector: 'enterprise-trial-form',
  templateUrl: './ee-trial-form.component.html',
  styleUrls: ['./ee-trial-form.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EETrialFormComponent {
  // Retain used values
  userData:Partial<IEnterpriseData> = this.eeTrialService.current.data || {};

  // The current request host
  requestHost = window.location.host;

  // The configured host name
  configuredHost = this.configurationService.hostName;

  trialForm = this.formBuilder.group({
    company: [this.userData.company, Validators.required],
    first_name: [this.userData.first_name, Validators.required],
    last_name: [this.userData.last_name, Validators.required],
    email: ['', [Validators.required, Validators.email]],
    domain: [this.userData.domain || this.configuredHost, Validators.required],
    general_consent: [null, Validators.required],
    newsletter_consent: null,
    language: this.currentUserService.language,
  });

  public text = {
    general_consent: this.I18n.t('js.admin.enterprise.trial.form.general_consent', {
      link_terms: localizeLink({
        en: 'https://www.openproject.org/terms-of-service/',
        de: 'https://www.openproject.org/de/nutzungsbedingungen/',
      }),
      link_privacy: localizeLink({
        en: 'https://www.openproject.org/data-privacy-and-security/',
        de: 'https://www.openproject.org/de/datenschutz/',
      }),
    }),
    label_test_ee: this.I18n.t('js.admin.enterprise.trial.form.test_ee'),
    label_company: this.I18n.t('js.admin.enterprise.trial.form.label_company'),
    label_first_name: this.I18n.t('js.admin.enterprise.trial.form.label_first_name'),
    label_last_name: this.I18n.t('js.admin.enterprise.trial.form.label_last_name'),
    label_email: this.I18n.t('js.label_email'),
    label_domain: this.I18n.t('js.admin.enterprise.trial.form.label_domain'),
    domain_mismatch: this.I18n.t('js.admin.enterprise.trial.form.domain_mismatch'),
    privacy_policy: this.I18n.t('js.admin.enterprise.trial.form.privacy_policy'),
    receive_newsletter: this.I18n.t('js.admin.enterprise.trial.form.receive_newsletter', { link: newsletterURL }),
    terms_of_service: this.I18n.t('js.admin.enterprise.trial.form.terms_of_service'),
  };

  constructor(
    readonly elementRef:ElementRef,
    readonly I18n:I18nService,
    readonly formBuilder:UntypedFormBuilder,
    readonly currentUserService:CurrentUserService,
    readonly configurationService:ConfigurationService,
    readonly eeTrialService:EnterpriseTrialService,
  ) {
  }

  // checks if mail is valid after input field was edited by the user
  // displays message for user
  public checkMailField():void {
    const data = this.trialForm.value as IEnterpriseData;
    if (data.email !== '' && this.trialForm.controls.email.errors) {
      this.eeTrialService.store.update({ emailInvalid: true });
    } else {
      this.eeTrialService.store.update({ emailInvalid: false, error: undefined });
    }
  }
}
