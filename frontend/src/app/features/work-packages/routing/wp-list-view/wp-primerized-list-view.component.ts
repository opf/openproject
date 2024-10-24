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

import { ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';
import {
  WorkPackageListViewComponent,
} from 'core-app/features/work-packages/routing/wp-list-view/wp-list-view.component';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { firstValueFrom } from 'rxjs';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Component({
  templateUrl: './wp-list-view.component.html',
  styleUrls: ['./wp-list-view.component.sass'],
  host: { class: 'op-primerized-work-packages-list work-packages-split-view--tabletimeline-side' },
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    { provide: HalResourceNotificationService, useClass: WorkPackageNotificationService },
    DragAndDropService,
    CausedUpdatesService,
  ],
})
export class WorkPackagePrimerizedListViewComponent extends WorkPackageListViewComponent implements OnInit {
  @InjectField() loadingIndicatorService:LoadingIndicatorService;
  @InjectField() wpListService:WorkPackagesListService;
  @InjectField() currentProject:CurrentProjectService;
  @InjectField() pathHelper:PathHelperService;

  currentQuery:QueryResource|undefined;

  ngOnInit() {
    this.loadInitialQuery();
    document.body.classList.add('router--work-packages-base');
    super.ngOnInit();
  }

  openStateLink(event:{ workPackageId:string; requestedState:'show'|'split' }) {
    if (event.requestedState === 'split') {
      this.openSplitScreen(event.workPackageId, this.keepTab.currentTabIdentifier);
    } else {
      this.openInFullView(event.workPackageId);
    }
  }

  openSplitScreen(workPackageId:string, tabIdentifier:string = 'overview'):void {
    let link = this.pathHelper.workPackagePrimerDetailsPath(this.currentProject.identifier, workPackageId, tabIdentifier);
    Turbo.visit(link + window.location.search, { frame: 'content-bodyRight', action: 'advance' });
  }

  openInFullView(workPackageId:string) {
    window.location.href = this.pathHelper.workPackagePath(workPackageId);
  }

  protected loadInitialQuery():void {
    const isFirstLoad = !this.querySpace.initialized.hasValue();
    this.loadingIndicator = this.loadQuery(isFirstLoad);
  }

  protected set loadingIndicator(promise:Promise<unknown>) {
    this.loadingIndicatorService.list.promise = promise;
  }

  protected loadQuery(firstPage = false):Promise<QueryResource> {
    let promise:Promise<QueryResource>;
    const query = this.currentQuery;

    if (firstPage || !query) {
      promise = this.loadFirstPage();
    } else {
      const pagination = this.wpListService.getPaginationInfo();
      promise = firstValueFrom(this.wpListService.loadQueryFromExisting(query, pagination, this.projectIdentifier));
    }

    return promise;
  }

  protected loadFirstPage():Promise<QueryResource> {
    if (this.currentQuery) {
      return firstValueFrom(this.wpListService.reloadQuery(this.currentQuery, this.projectIdentifier));
    }
    return this.wpListService.loadCurrentQueryFromParams(this.projectIdentifier);
  }

  public get projectIdentifier() {
    return this.currentProject.identifier || undefined;
  }

}
