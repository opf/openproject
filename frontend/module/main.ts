//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2021 Ben Tey
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { Injector, NgModule } from '@angular/core';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import { WorkPackageTabsService } from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';


import { GitlabTabComponent } from './gitlab-tab/gitlab-tab.component';
import { TabHeaderComponent } from './tab-header/tab-header.component';
import { TabMrsComponent } from './tab-mrs/tab-mrs.component';
import { GitActionsMenuDirective } from './git-actions-menu/git-actions-menu.directive';
import { GitActionsMenuComponent } from './git-actions-menu/git-actions-menu.component';
import { WorkPackagesGitlabMrsService } from './tab-mrs/wp-gitlab-mrs.service';
import { MergeRequestComponent } from './merge-request/merge-request.component';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export function workPackageGitlabMrsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const gitlabMrsService = injector.get(WorkPackagesGitlabMrsService);
  return gitlabMrsService
    .requireAndStream(workPackage)
    .pipe(
      map((mrs) => mrs.length),
    );
}

export function initializeGitlabIntegrationPlugin(injector:Injector) {
  const wpTabService = injector.get(WorkPackageTabsService);
  wpTabService.register({
    component: GitlabTabComponent,
    name: I18n.t('js.gitlab_integration.work_packages.tab_name'),
    id: 'gitlab',
    displayable: (workPackage) => !!workPackage.gitlab,
    count: workPackageGitlabMrsCount,
  });
}


@NgModule({
  imports: [
    OpSharedModule,
    OpenprojectTabsModule,
  ],
  providers: [
    WorkPackagesGitlabMrsService,
  ],
  declarations: [
    GitlabTabComponent,
    TabHeaderComponent,
    TabMrsComponent,
    GitActionsMenuDirective,
    GitActionsMenuComponent,
    MergeRequestComponent,
  ],
  exports: [
    GitlabTabComponent,
    TabHeaderComponent,
    TabMrsComponent,
    GitActionsMenuDirective,
    GitActionsMenuComponent,
  ],
})
export class PluginModule {
  constructor(injector:Injector) {
    initializeGitlabIntegrationPlugin(injector);
  }
}
