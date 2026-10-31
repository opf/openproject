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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { CUSTOM_ELEMENTS_SCHEMA, Injector, NgModule, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, combineLatest, of } from 'rxjs';
import { map } from 'rxjs/operators';

import { OpSharedModule } from 'core-app/shared/shared.module';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import {
  WorkPackageTabsService,
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';

import { RepositoriesTabComponent } from './repositories-tab/repositories-tab.component';

const REPOSITORY_RESOURCE_LINKS = [
  'repositoryIssues',
  'repositoryMergeRequests',
  'repositoryBranches',
  'repositoryCommits',
] as const;

export function workPackageRepositoriesCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const http = injector.get(HttpClient);

  const totals = REPOSITORY_RESOURCE_LINKS.map((name) => {
    const link = workPackage.$links[name] as CallableHalLink|undefined;

    return link
      ? http.get<IHALCollection<unknown>>(`${link.href}?pageSize=0`).pipe(map((collection) => collection.total))
      : of(0);
  });

  return combineLatest(totals).pipe(
    map((counts) => counts.reduce((sum, count) => sum + count, 0)),
  );
}

export function initializeRepositoriesPlugin(injector:Injector) {
  const wpTabService = injector.get(WorkPackageTabsService);
  wpTabService.registerBefore(
    'watchers',
    {
      component: RepositoriesTabComponent,
      name: I18n.t('js.work_packages.tabs.repositories'),
      id: 'repositories',
      displayable: (workPackage) => !!workPackage.repositories,
      count: workPackageRepositoriesCount,
    },
  );
}


@NgModule({
  imports: [
    OpSharedModule,
    OpenprojectTabsModule,
  ],
  providers: [],
  declarations: [
    RepositoriesTabComponent,
  ],
  exports: [
    RepositoriesTabComponent,
  ],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
})
export class PluginModule {
  constructor() {
    const injector = inject(Injector);

    initializeRepositoriesPlugin(injector);
  }
}
