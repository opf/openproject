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

import {Component, ElementRef} from "@angular/core";
import {FormBuilder, Validators} from "@angular/forms";
import {I18nService} from "app/modules/common/i18n/i18n.service";
import {EnterpriseTrialData, EnterpriseTrialService} from "core-components/enterprise/enterprise-trial.service";
import {CurrentUserService} from "core-components/user/current-user.service";
import {I18nHelpers} from "core-app/helpers/i18n/localized-link";

const newsletterURL = 'https://www.openproject.com/newsletter/';

@Component({
  selector: 'enterprise-trial-form',
  templateUrl: './ee-trial-form.component.html'
})
export class EETrialFormComponent {
  // Retain used values
  userData:Partial<EnterpriseTrialData> = this.eeTrialService.userData$.getValueOr({});

  trialForm = this.formBuilder.group({
    company: [this.userData.company, Validators.required],
    first_name: [this.userData.first_name, Validators.required],
    last_name: [this.userData.last_name, Validators.required],
    email: ['', [Validators.required, Validators.email]],
    domain: [this.userData.domain || window.location.host, Validators.required],
    general_consent: [null, Validators.required],
    newsletter_consent: null,
    language: this.currentUserService.language
  });

  public text = {
    general_consent: this.I18n.t('js.admin.enterprise.trial.form.general_consent', {
      link_terms: I18nHelpers.localizeLink({
        en: 'https://www.openproject.com/terms-of-service/',
        de: 'https://www.openproject.org/de/nutzungsbedingungen/',
      }),
      link_privacy: I18nHelpers.localizeLink({
        en: 'https://www.openproject.org/data-privacy-and-security/',
        de: 'https://www.openproject.org/de/datenschutz/'
      })
    }),
    label_test_ee: this.I18n.t('js.admin.enterprise.trial.form.test_ee'),
    label_company: this.I18n.t('js.admin.enterprise.trial.form.label_company'),
    label_first_name: this.I18n.t('js.admin.enterprise.trial.form.label_first_name'),
    label_last_name: this.I18n.t('js.admin.enterprise.trial.form.label_last_name'),
    label_email: this.I18n.t('js.admin.enterprise.trial.form.label_email'),
    label_domain: this.I18n.t('js.admin.enterprise.trial.form.label_domain'),
    privacy_policy: this.I18n.t('js.admin.enterprise.trial.form.privacy_policy'),
    receive_newsletter: this.I18n.t('js.admin.enterprise.trial.form.receive_newsletter', { link: newsletterURL }),
    terms_of_service: this.I18n.t('js.admin.enterprise.trial.form.terms_of_service')
  };

  constructor(readonly elementRef:ElementRef,
              readonly I18n:I18nService,
              private formBuilder:FormBuilder,
              readonly currentUserService:CurrentUserService,
              public eeTrialService:EnterpriseTrialService) {

  }

  // checks if mail is valid after input field was edited by the user
  // displays message for user
  public checkMailField() {
    if (this.trialForm.value.email !== '' && this.trialForm.controls.email.errors) {
      this.eeTrialService.emailInvalid = true;
    } else {
      this.eeTrialService.emailInvalid = false;
      this.eeTrialService.error = undefined;
    }
  }
}

