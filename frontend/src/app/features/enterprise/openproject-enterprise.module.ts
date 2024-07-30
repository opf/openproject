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

import { NgModule } from '@angular/core';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { EnterpriseTrialService } from 'core-app/features/enterprise/enterprise-trial.service';
import { EnterpriseBaseComponent } from 'core-app/features/enterprise/enterprise-base.component';
import { EnterpriseTrialModalComponent } from 'core-app/features/enterprise/enterprise-modal/enterprise-trial.modal';
import { EETrialFormComponent } from 'core-app/features/enterprise/enterprise-modal/enterprise-trial-form/ee-trial-form.component';
import { EETrialWaitingComponent } from 'core-app/features/enterprise/enterprise-trial-waiting/ee-trial-waiting.component';
import { EEActiveTrialComponent } from 'core-app/features/enterprise/enterprise-active-trial/ee-active-trial.component';
import { EEActiveSavedTrialComponent } from 'core-app/features/enterprise/enterprise-active-trial/ee-active-saved-trial.component';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

@NgModule({
  imports: [
    OpSharedModule,
    OpenprojectModalModule,
    FormsModule,
    ReactiveFormsModule,
  ],
  providers: [
    EnterpriseTrialService,
  ],
  exports: [
  ],
  declarations: [
    EnterpriseBaseComponent,
    EnterpriseTrialModalComponent,
    EETrialFormComponent,
    EETrialWaitingComponent,
    EEActiveTrialComponent,
    EEActiveSavedTrialComponent,
  ],
})
export class OpenprojectEnterpriseModule {
}
