// -- copyright
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
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy,
  Component,
  Injector,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { EnterpriseTrialModalComponent } from 'core-app/features/enterprise/enterprise-modal/enterprise-trial.modal';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { EnterpriseTrialService } from 'core-app/features/enterprise/enterprise-trial.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { distinctUntilChanged } from 'rxjs/operators';

export const freeTrialButtonSelector = 'free-trial-button';

@Component({
  selector: freeTrialButtonSelector,
  templateUrl: './free-trial-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FreeTrialButtonComponent {
  created = this.timezoneService.formattedDate(new Date().toString());

  email = '';

  public text = {
    button_trial: this.I18n.t('js.admin.enterprise.upsale.button_start_trial'),
    confirmation_info: (date:string, email:string) => this.trialRequested ? this.I18n.t('js.admin.enterprise.trial.confirmation_info', {
      date,
      email,
    }): '',
  };

  constructor(protected I18n:I18nService,
    protected opModalService:OpModalService,
    readonly injector:Injector,
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
      .subscribe((userForm) => {
        this.email = userForm.email;
      });
  }
  public openTrialModal():void {
    // cancel request and open first modal window
    this.eeTrialService.cancelled = true;
    this.eeTrialService.modalOpen = true;
    this.opModalService.show(EnterpriseTrialModalComponent, this.injector);
  }
  public get trialRequested() {
    return window.gon.ee_trial_key !== undefined;
  }
}
