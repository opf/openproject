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

import { ChangeDetectionStrategy, Component, Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { EnterpriseTrialModalComponent } from 'core-app/features/enterprise/enterprise-modal/enterprise-trial.modal';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { EnterpriseTrialService } from 'core-app/features/enterprise/enterprise-trial.service';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'enterprise-base',
  templateUrl: './enterprise-base.component.html',
  styleUrls: ['./enterprise-base.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
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
    try_another_email: this.I18n.t('js.admin.enterprise.trial.try_another_email'),
  };

  constructor(
    protected I18n:I18nService,
    protected opModalService:OpModalService,
    readonly injector:Injector,
    public eeTrialService:EnterpriseTrialService,
  ) {
  }

  public openTrialModal() {
    // cancel request and open first modal window
    this.eeTrialService.store.update({ cancelled: true, modalOpen: true });
    this.opModalService.show(EnterpriseTrialModalComponent, this.injector);
  }

  public get noTrialRequested() {
    return window.gon.ee_trial_key === undefined;
  }
}
