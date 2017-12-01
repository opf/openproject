// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';
import {UpgradeModule} from '@angular/upgrade/static';
import {TablePaginationComponent} from 'core-app/components/table-pagination/table-pagination.component';
import {AccessibleByKeyboardDirectiveUpgraded} from 'core-app/ui_components/accessible-by-keyboard-directive-upgraded';
import {OpIcon} from 'core-components/common/icon/op-icon';
import {ContextMenuService} from 'core-components/context-menus/context-menu.service';
import {HasDropdownMenuDirective} from 'core-components/context-menus/has-dropdown-menu/has-dropdown-menu-directive';
import {States} from 'core-components/states.service';
import {PaginationService} from 'core-components/table-pagination/pagination-service';
import {WorkPackageDisplayFieldService} from 'core-components/wp-display/wp-display-field/wp-display-field.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {WorkPackageTableColumnsService} from 'core-components/wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableGroupByService} from 'core-components/wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableHierarchiesService} from 'core-components/wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTablePaginationService} from 'core-components/wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTableTimelineService} from 'core-components/wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageRelationsService} from 'core-components/wp-relations/wp-relations.service';
import {WorkPackageTablePaginationComponent} from 'core-components/wp-table/table-pagination/wp-table-pagination.component';
import {WorkPackageTimelineTableController} from 'core-components/wp-table/timeline/container/wp-timeline-container.directive';
import {WorkPackageTableTimelineRelations} from 'core-components/wp-table/timeline/global-elements/wp-timeline-relations.directive';
import {WorkPackageTableTimelineStaticElements} from 'core-components/wp-table/timeline/global-elements/wp-timeline-static-elements.directive';
import {WorkPackageTableTimelineGrid} from 'core-components/wp-table/timeline/grid/wp-timeline-grid.directive';
import {WorkPackageTimelineHeaderController} from 'core-components/wp-table/timeline/header/wp-timeline-header.directive';
import {
  WorkPackagesTableController,
  WorkPackagesTableControllerHolder
} from 'core-components/wp-table/wp-table.directive';
import {
  $rootScopeToken,
  columnsModalToken, focusHelperToken,
  I18nToken,
  NotificationsServiceToken,
  upgradeService,
  upgradeServiceWithToken
} from './angular4-transition-utils';
import {WpResizerDirectiveUpgraded} from 'core-components/wp-resizer/wp-resizer.directive';
import {WorkPackageTableSumsRowController} from 'core-components/wp-table/wp-table-sums-row/wp-table-sums-row.directive';
import {SortHeaderDirective} from 'core-components/wp-table/sort-header/sort-header.directive';
import {WorkPackageTableSortByService} from 'core-components/wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableRelationColumnsService} from 'core-components/wp-fast-table/state/wp-table-relation-columns.service';


@NgModule({
  imports: [
    BrowserModule,
    UpgradeModule
  ],
  providers: [
    WorkPackagesTableControllerHolder,
    upgradeService('wpRelations', WorkPackageRelationsService),
    upgradeService('states', States),
    upgradeService('paginationService', PaginationService),
    upgradeService('wpTablePagination', WorkPackageTablePaginationService),
    upgradeService('wpDisplayField', WorkPackageDisplayFieldService),
    upgradeService('wpTableTimeline', WorkPackageTableTimelineService),
    upgradeService('wpNotificationsService', WorkPackageNotificationService),
    upgradeService('wpTableHierarchies', WorkPackageTableHierarchiesService),
    upgradeService('wpTableSortBy', WorkPackageTableSortByService),
    upgradeService('wpTableRelationColumns', WorkPackageTableRelationColumnsService),
    upgradeService('wpTableGroupBy', WorkPackageTableGroupByService),
    upgradeService('wpTableColumns', WorkPackageTableColumnsService),
    upgradeService('contextMenu', ContextMenuService),
    upgradeServiceWithToken('$rootScope', $rootScopeToken),
    upgradeServiceWithToken('I18n', I18nToken),
    upgradeServiceWithToken('NotificationsService', NotificationsServiceToken),
    upgradeServiceWithToken('columnsModal', columnsModalToken),
    upgradeServiceWithToken('FocusHelper', focusHelperToken)
  ],
  declarations: [
    OpIcon,
    AccessibleByKeyboardDirectiveUpgraded,
    TablePaginationComponent,
    WorkPackageTablePaginationComponent,
    WorkPackageTimelineHeaderController,
    WorkPackageTableTimelineRelations,
    WorkPackageTableTimelineStaticElements,
    WorkPackageTableTimelineGrid,
    WorkPackageTimelineTableController,
    WorkPackagesTableController,
    WpResizerDirectiveUpgraded,
    WorkPackageTableSumsRowController,
    SortHeaderDirective,
    HasDropdownMenuDirective
  ],
  entryComponents: [
    WorkPackageTablePaginationComponent,
    WorkPackagesTableController,
    TablePaginationComponent
  ]
})
export class OpenProjectModule {
  constructor(private upgrade:UpgradeModule) {
  }

  // noinspection JSUnusedGlobalSymbols
  ngDoBootstrap() {
    this.upgrade.bootstrap(document.body, ['openproject'], {strictDi: false});
  }
}


setTimeout(function() {
  platformBrowserDynamic().bootstrapModule(OpenProjectModule);
}, 0);
