//-- copyright
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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Injector,
  OnInit,
  ElementRef,
  NgZone
} from "@angular/core";
import { take } from "rxjs/operators";
import { CausedUpdatesService } from "core-app/modules/boards/board/caused-updates/caused-updates.service";
import { DragAndDropService } from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {
  WorkPackageViewDisplayRepresentationService,
  wpDisplayCardRepresentation
} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import { WorkPackageTableConfigurationObject } from "core-components/wp-table/wp-table-configuration";
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { DeviceService } from "core-app/modules/common/browser/device.service";
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { WorkPackageViewFiltersService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { QueryResource } from "core-app/modules/hal/resources/query-resource";
import { StateService } from "@uirouter/core";
import { KeepTabService } from "core-components/wp-single-view-tabs/keep-tab/keep-tab.service";

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
  showTableView = true;

  /** Determine when query is initially loaded */
  tableInformationLoaded = false;

  /** If loaded list of work packages is empty */
  noResults = false;

  /** Whether we should render a blocked view */
  showResultOverlay$ = this.wpViewFilters.incomplete$;

  /** */
  readonly wpTableConfiguration:WorkPackageTableConfigurationObject = {
    dragAndDropEnabled: true
  };

  constructor(readonly I18n:I18nService,
              readonly injector:Injector,
              readonly $state:StateService,
              readonly keepTab:KeepTabService,
              readonly querySpace:IsolatedQuerySpace,
              readonly wpViewFilters:WorkPackageViewFiltersService,
              readonly deviceService:DeviceService,
              readonly CurrentProject:CurrentProjectService,
              readonly wpDisplayRepresentation:WorkPackageViewDisplayRepresentationService,
              readonly cdRef:ChangeDetectorRef,
              readonly elementRef:ElementRef,
              private ngZone:NgZone) {
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

    // Scroll into view the card/row that represents the last selected WorkPackage
    // so when the user opens a WP detail page on a split-view and then clicks on
    // the 'back button', the last selected card is visible on this list.
    // ngAfterViewInit doesn't find the .-checked elements on components
    // that inherit from this class (BcfListContainerComponent) so
    // opting for a timeout 'runOutsideAngular' to avoid running change
    // detection on the entire app
    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => {
        const selectedRow = this.elementRef.nativeElement.querySelector('.wp-table--row.-checked');
        const selectedCard = this.elementRef.nativeElement.querySelector('.wp-card.-checked');

        // The header of the table hides the scrolledIntoView element
        // so we scrollIntoView the previous element, if any
        if (selectedRow && selectedRow.previousSibling) {
          selectedRow.previousSibling.scrollIntoView({ block: "start" });
        }

        if (selectedCard) {
          selectedCard.scrollIntoView({ block: "start" });
        }
      }, 0);
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

  public showResizerInCardView():boolean {
    return false;
  }

  protected updateViewRepresentation(query:QueryResource) {
    this.showTableView = !(this.deviceService.isMobile ||
      this.wpDisplayRepresentation.valueFromQuery(query) === wpDisplayCardRepresentation);
  }

  handleWorkPackageClicked(event:{ workPackageId:string; double:boolean }) {
    if (event.double) {
      this.openInFullView(event.workPackageId);
    }
  }

  openStateLink(event:{ workPackageId:string; requestedState:string }) {
    this.$state.go(
      (this.keepTab as any)[event.requestedState] || event.requestedState,
      { workPackageId: event.workPackageId, focus: true }
    );
  }

  /**
   * Special handling for clicking on cards.
   * If we are on mobile, a click on the card should directly open the full view
   */
  handleWorkPackageCardClicked(event:{ workPackageId:string; double:boolean }) {
    if (this.deviceService.isMobile) {
      this.openInFullView(event.workPackageId);
    } else {
      this.handleWorkPackageClicked(event);
    }
  }

  private openInFullView(workPackageId:string) {
    this.$state.go(
      'work-packages.show',
      { workPackageId: workPackageId }
    );
  }
}
