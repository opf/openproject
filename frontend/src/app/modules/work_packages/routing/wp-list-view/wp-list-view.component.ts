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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  HostBinding,
  Input,
  OnDestroy,
  OnInit
} from "@angular/core";
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {OpTitleService} from "core-components/html/op-title.service";
import {WorkPackagesViewBase} from "core-app/modules/work_packages/routing/wp-view-base/work-packages-view.base";
import {take} from "rxjs/operators";
import {CausedUpdatesService} from "core-app/modules/boards/board/caused-updates/caused-updates.service";
import {DragAndDropService} from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {BcfDetectorService} from "core-app/modules/bcf/helper/bcf-detector.service";
import {
  WorkPackageViewDisplayRepresentationService,
  wpDisplayCardRepresentation
} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {DeviceService} from "core-app/modules/common/browser/device.service";

@Component({
  selector: 'wp-list-view',
  templateUrl: './wp-list-view.component.html',
  host: { 'class': 'work-packages-split-view--tabletimeline-side' },
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    DragAndDropService,
    CausedUpdatesService
  ]
})
export class WorkPackageListViewComponent implements OnInit, OnDestroy {
  /** An overlay over the table shown for example when the filters are invalid */
  @Input() showResultOverlay:boolean;

  /** Current project identifier */
  @Input() projectIdentifier:string|undefined;

  text = {
    'jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.pagination'),
    'text_jump_to_pagination': this.I18n.t('js.work_packages.jump_marks.label_pagination'),
    'button_settings': this.I18n.t('js.button_settings')
  };

  /** Determine when query is initially loaded */
  tableInformationLoaded = false;

  /** Switch between list and card view */
  showListView:boolean = true;

  /** */
  readonly wpTableConfiguration:WorkPackageTableConfigurationObject = {
    dragAndDropEnabled: true
  };

  constructor(private I18n:I18nService,
              private querySpace:IsolatedQuerySpace,
              private deviceService:DeviceService,
              private wpDisplayRepresentation:WorkPackageViewDisplayRepresentationService,
              private cdRef:ChangeDetectorRef) {
  }

  ngOnInit() {

    // Mark tableInformationLoaded when initially loading done
    this.setupInformationLoadedListener();

    this.querySpace.query.values$().pipe(
      untilComponentDestroyed(this)
    ).subscribe((query) => {
      // Update the visible representation
      this.showListView = !(this.deviceService.isMobile || this.wpDisplayRepresentation.valueFromQuery(query) === wpDisplayCardRepresentation);
      this.cdRef.detectChanges();
    });
  }
  ngOnDestroy():void {
    // Nothing to do
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
}
