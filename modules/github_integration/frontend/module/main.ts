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
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.

import { Injector, NgModule } from '@angular/core';
import { OPSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import { WorkPackageTabsService } from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { GitHubTabComponent } from './github-tab/github-tab.component';
import { TabHeaderComponent } from './tab-header/tab-header.component';
import { TabPrsComponent } from './tab-prs/tab-prs.component';
import { GitActionsMenuDirective } from './git-actions-menu/git-actions-menu.directive';
import { GitActionsMenuComponent } from './git-actions-menu/git-actions-menu.component';
import { WorkPackagesGithubPrsService } from './tab-prs/wp-github-prs.service';
import { PullRequestComponent } from './pull-request/pull-request.component';

export function initializeGithubIntegrationPlugin(injector:Injector) {
  const wpTabService = injector.get(WorkPackageTabsService);
  wpTabService.register({
    component: GitHubTabComponent,
    name: I18n.t('js.github_integration.work_packages.tab_name'),
    id: 'github',
    displayable: (workPackage) => !!workPackage.github,
  });
}

@NgModule({
  imports: [
    OPSharedModule,
    OpenprojectTabsModule,
  ],
  providers: [
    WorkPackagesGithubPrsService,
  ],
  declarations: [
    GitHubTabComponent,
    TabHeaderComponent,
    TabPrsComponent,
    GitActionsMenuDirective,
    GitActionsMenuComponent,
    PullRequestComponent,
  ],
  exports: [
    GitHubTabComponent,
    TabHeaderComponent,
    TabPrsComponent,
    GitActionsMenuDirective,
    GitActionsMenuComponent,
  ],
})
export class PluginModule {
  constructor(injector:Injector) {
    initializeGithubIntegrationPlugin(injector);
  }
}
