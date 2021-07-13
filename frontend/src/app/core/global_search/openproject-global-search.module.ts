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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { NgModule } from '@angular/core';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { GlobalSearchInputComponent } from 'core-app/core/global_search/input/global-search-input.component';
import { GlobalSearchWorkPackagesComponent } from 'core-app/core/global_search/global-search-work-packages.component';
import { GlobalSearchTabsComponent } from 'core-app/core/global_search/tabs/global-search-tabs.component';
import { GlobalSearchTitleComponent } from 'core-app/core/global_search/title/global-search-title.component';
import { GlobalSearchService } from 'core-app/core/global_search/services/global-search.service';
import { GlobalSearchWorkPackagesEntryComponent } from 'core-app/core/global_search/global-search-work-packages-entry.component';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { OPSharedModule } from 'core-app/shared/shared.module';

@NgModule({
  imports: [
    OPSharedModule,
    OpenprojectWorkPackagesModule,
    OpenprojectAutocompleterModule,
  ],
  providers: [
    GlobalSearchService,
  ],
  declarations: [
    GlobalSearchInputComponent,
    GlobalSearchWorkPackagesEntryComponent,
    GlobalSearchWorkPackagesComponent,
    GlobalSearchTabsComponent,
    GlobalSearchTitleComponent,
  ],
})
export class OpenprojectGlobalSearchModule { }
