// -- copyright
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
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.

import { Injector, NgModule, } from '@angular/core';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { OpenprojectTabsModule } from 'core-app/shared/components/tabs/openproject-tabs.module';
import {
  WorkPackageTabsService
} from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { GitHubTabComponent } from './github-tab/github-tab.component';
import { TabHeaderComponent } from './tab-header/tab-header.component';
import { TabPrsComponent } from './tab-prs/tab-prs.component';
import { GitActionsMenuDirective } from './git-actions-menu/git-actions-menu.directive';
import { GitActionsMenuComponent } from './git-actions-menu/git-actions-menu.component';
import { PullRequestComponent } from './pull-request/pull-request.component';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { GithubPullRequestResourceService } from './state/github-pull-request.service';
import { PullRequestMacroComponent, } from './pull-request/pull-request-macro.component';
import { PullRequestStateComponent } from './pull-request/pull-request-state.component';
import { registerCustomElement } from 'core-app/shared/helpers/angular/custom-elements.helper';

export function workPackageGithubPrsCount(
  workPackage:WorkPackageResource,
  injector:Injector,
):Observable<number> {
  const githubPrsService = injector.get(GithubPullRequestResourceService);
  return githubPrsService
    .ofWorkPackage(workPackage)
    .pipe(
      map((prs) => prs.length),
    );
}

export function initializeGithubIntegrationPlugin(injector:Injector) {
  const wpTabService = injector.get(WorkPackageTabsService);
  wpTabService.register({
    component: GitHubTabComponent,
    name: I18n.t('js.github_integration.work_packages.tab_name'),
    id: 'github',
    displayable: (workPackage) => !!workPackage.github,
    count: workPackageGithubPrsCount,
  });
}

@NgModule({
  imports: [
    OpSharedModule,
    OpenprojectTabsModule,
  ],
  providers: [
    GithubPullRequestResourceService,
  ],
  declarations: [
    GitHubTabComponent,
    TabHeaderComponent,
    TabPrsComponent,
    GitActionsMenuDirective,
    GitActionsMenuComponent,
    PullRequestComponent,
    PullRequestMacroComponent,
    PullRequestStateComponent,
  ],
  exports: [
    GitHubTabComponent,
    TabHeaderComponent,
    TabPrsComponent,
    GitActionsMenuDirective,
    GitActionsMenuComponent,
    PullRequestMacroComponent,
  ],
})
export class PluginModule {
  constructor(injector:Injector) {
    initializeGithubIntegrationPlugin(injector);
    registerCustomElement('opce-github-pull-request', PullRequestMacroComponent, { injector });
  }
}
