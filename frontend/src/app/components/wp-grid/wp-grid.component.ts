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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, Output } from "@angular/core";
import { WorkPackageViewHighlightingService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-highlighting.service";
import { CardViewOrientation } from "core-components/wp-card-view/wp-card-view.component";
import { WorkPackageViewSortByService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sort-by.service";
import { distinctUntilChanged, takeUntil } from "rxjs/operators";
import { HighlightingMode } from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { DragAndDropService } from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import { WorkPackageCardDragAndDropService } from "core-components/wp-card-view/services/wp-card-drag-and-drop.service";
import { WorkPackagesListService } from "core-components/wp-list/wp-list.service";
import { WorkPackageTableConfiguration } from "core-components/wp-table/wp-table-configuration";
import { WorkPackageViewOutputs } from "core-app/modules/work_packages/routing/wp-view-base/event-handling/event-handler-registry";

@Component({
  selector: 'wp-grid',
  template: `
    <wp-card-view [dragOutOfHandler]="canDragOutOf"
                  [dragInto]="dragInto"
                  [cardsRemovable]="false"
                  [highlightingMode]="highlightingMode"
                  [showStatusButton]="true"
                  [orientation]="gridOrientation"
                  (onMoved)="switchToManualSorting()"
                  (selectionChanged)="selectionChanged.emit($event)"
                  (itemClicked)="itemClicked.emit($event)"
                  (stateLinkClicked)="stateLinkClicked.emit($event)"
                  [showEmptyResultsBox]="true"
                  [showInfoButton]="true"
                  [shrinkOnMobile]="true">
    </wp-card-view>

    <div *ngIf="showResizer"
         class="hidden-for-mobile hide-when-print">
      <wp-resizer [elementClass]="resizerClass"
                  [localStorageKey]="resizerStorageKey"></wp-resizer>
    </div>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    DragAndDropService,
    WorkPackageCardDragAndDropService
  ]
})
export class WorkPackagesGridComponent implements WorkPackageViewOutputs {
  @Input() public configuration:WorkPackageTableConfiguration;
  @Input() public showResizer = false;
  @Input() public resizerClass = '';
  @Input() public resizerStorageKey = '';

  @Output() selectionChanged = new EventEmitter<string[]>();
  @Output() itemClicked = new EventEmitter<{ workPackageId:string, double:boolean }>();
  @Output() stateLinkClicked = new EventEmitter<{ workPackageId:string, requestedState:string }>();

  public canDragOutOf:() => boolean;
  public dragInto:boolean;
  public gridOrientation:CardViewOrientation = 'horizontal';
  public highlightingMode:HighlightingMode = 'none';

  constructor(readonly wpTableHighlight:WorkPackageViewHighlightingService,
              readonly wpTableSortBy:WorkPackageViewSortByService,
              readonly wpList:WorkPackagesListService,
              readonly querySpace:IsolatedQuerySpace,
              readonly cdRef:ChangeDetectorRef) {
  }

  ngOnInit() {
    this.dragInto = this.configuration.dragAndDropEnabled;
    this.canDragOutOf = () => {
      return this.configuration.dragAndDropEnabled;
    };

    this.wpTableHighlight
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
        distinctUntilChanged()
      )
      .subscribe(() => {
        this.highlightingMode = this.wpTableHighlight.current.mode;
        this.cdRef.detectChanges();
      });

  }

  public switchToManualSorting() {
    const query = this.querySpace.query.value;
    if (query && this.wpTableSortBy.switchToManualSorting(query)) {
      this.wpList.save(query);
    }
  }
}
