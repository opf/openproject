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

import { NgModule } from '@angular/core';
import { OPSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectModalModule } from 'core-app/shared/components/modal/modal.module';
import { OpenprojectFieldsModule } from 'core-app/shared/components/fields/openproject-fields.module';
import { TimeEntryCreateModalComponent } from 'core-app/shared/components/time_entries/create/create.modal';
import { TimeEntryEditModalComponent } from 'core-app/shared/components/time_entries/edit/edit.modal';
import { TimeEntryFormComponent } from 'core-app/shared/components/time_entries/form/form.component';
import { TimeEntryEditService } from 'core-app/shared/components/time_entries/edit/edit.service';
import { TriggerActionsEntryComponent } from 'core-app/shared/components/time_entries/edit/trigger-actions-entry.component';

@NgModule({
  imports: [
    // Commons
    OPSharedModule,
    OpenprojectModalModule,

    // Editable fields e.g. for modals
    OpenprojectFieldsModule,
  ],
  providers: [
    TimeEntryEditService,
  ],
  declarations: [
    TimeEntryEditModalComponent,
    TimeEntryCreateModalComponent,
    TimeEntryFormComponent,
    TriggerActionsEntryComponent,
  ],
})
export class OpenprojectTimeEntriesModule {
}
