// -- copyright
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
// ++

import {Component, Injector} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {EnterpriseTrialModal} from "core-components/enterprise/enterprise-modal/enterprise-trial.modal";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {EnterpriseTrialService} from "core-components/enterprise/enterprise-trial.service";

export const enterpriseBaseSelector = 'enterprise-base';

@Component({
  selector: enterpriseBaseSelector,
  templateUrl: './enterprise-base.component.html',
  styleUrls: ['./enterprise-base.component.sass']
})
export class EnterpriseBaseComponent {
  public text = {
    button_trial: this.I18n.t('js.admin.enterprise.upsale.button_start_trial'),
    button_book: this.I18n.t('js.admin.enterprise.upsale.button_book_now'),
    link_quote: this.I18n.t('js.admin.enterprise.upsale.link_quote'),
    become_hero: this.I18n.t('js.admin.enterprise.upsale.become_hero'),
    you_contribute: this.I18n.t('js.admin.enterprise.upsale.you_contribute'),
    email_not_received: this.I18n.t('js.admin.enterprise.trial.email_not_received'),
    enterprise_edition: this.I18n.t('js.admin.enterprise.upsale.text'),
    confidence: this.I18n.t('js.admin.enterprise.upsale.confidence'),
    try_another_email: this.I18n.t('js.admin.enterprise.trial.try_another_email')
  };

  constructor(protected I18n:I18nService,
              protected opModalService:OpModalService,
              readonly injector:Injector,
              public eeTrialService:EnterpriseTrialService) {
  }

  public openTrialModal() {
    // cancel request and open first modal window
    this.eeTrialService.cancelled = true;
    this.eeTrialService.modalOpen = true;
    this.opModalService.show(EnterpriseTrialModal, this.injector);
  }

  public get noTrialRequested() {
    return this.eeTrialService.status === undefined;
  }
}
