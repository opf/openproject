// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, OnInit} from "@angular/core";
import {take} from "rxjs/operators";
import {CausedUpdatesService} from "core-app/modules/boards/board/caused-updates/caused-updates.service";
import {DragAndDropService} from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {
  WorkPackageViewDisplayRepresentationService,
  wpDisplayCardRepresentation
} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {DeviceService} from "core-app/modules/common/browser/device.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {WorkPackageViewFiltersService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";

@Component({
  selector: 'wp-list-view',
  templateUrl: './wp-list-view.component.html',
  styleUrls: ['./wp-list-view.component.sass'],
  host: { 'class': 'work-packages-split-view--tabletimeline-side' },
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    { provide: HalResourceNotificationService, useClass: WorkPackageNotificationService },
    DragAndDropService,
    CausedUpdatesService
  ]
})
export class WorkPackageListViewComponent extends UntilDestroyedMixin implements OnInit {

  text = {
    'jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.pagination'),
    'text_jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.label_pagination'),
    'button_settings': this.I18n.t('js.button_settings')
  };

  /** Switch between list and card view */
  showListView:boolean = true;

  /** Determine when query is initially loaded */
  tableInformationLoaded = false;

  /** If loaded list of work packages is empty */
  noResults:boolean = false;

  /** Whether we should render a blocked view */
  showResultOverlay$ = this.wpViewFilters.incomplete$;

  /** */
  readonly wpTableConfiguration:WorkPackageTableConfigurationObject = {
    dragAndDropEnabled: true
  };

  constructor(readonly I18n:I18nService,
              readonly injector:Injector,
              readonly querySpace:IsolatedQuerySpace,
              readonly wpViewFilters:WorkPackageViewFiltersService,
              readonly deviceService:DeviceService,
              readonly CurrentProject:CurrentProjectService,
              readonly wpDisplayRepresentation:WorkPackageViewDisplayRepresentationService,
              readonly cdRef:ChangeDetectorRef) {
    super();
  }

  ngOnInit() {
    // Mark tableInformationLoaded when initially loading done
    this.setupInformationLoadedListener();

    this.querySpace.query.values$().pipe(
      this.untilDestroyed()
    ).subscribe((query) => {
      // Update the visible representation
      this.updateViewRepresentation(query);
      this.noResults = query.results.total === 0;
      this.cdRef.detectChanges();
    });
  }

  protected setupInformationLoadedListener() {
    this
      .querySpace
      .initialized
      .values$()
      .pipe(take(1))
      .subscribe(() => {
        this.tableInformationLoaded = true;
        this.cdRef.detectChanges();
      });
  }

  protected showResizerInCardView():boolean {
    return false;
  }

  protected updateViewRepresentation(query:QueryResource) {
    this.showListView = !(this.deviceService.isMobile ||
      this.wpDisplayRepresentation.valueFromQuery(query) === wpDisplayCardRepresentation);
  }
}
