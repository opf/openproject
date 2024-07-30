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

import {
  ChangeDetectionStrategy,
  Component,
  Injector,
  OnInit,
  ViewEncapsulation,
} from '@angular/core';
import {
  PartitionedQuerySpacePageComponent,
  ToolbarButtonComponentDefinition,
} from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import {
  WorkPackageFilterButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-filter-button/wp-filter-button.component';
import {
  ZenModeButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import {
  bcfSplitViewCardsIdentifier,
  bcfViewerViewIdentifier,
  BcfViewService,
} from 'core-app/features/bim/ifc_models/pages/viewer/bcf-view.service';
import {
  BcfViewToggleButtonComponent,
} from 'core-app/features/bim/ifc_models/toolbar/view-toggle/bcf-view-toggle-button.component';
import { IfcModelsDataService } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-models-data.service';
import {
  QueryParamListenerService,
} from 'core-app/features/work-packages/components/wp-query/query-param-listener.service';
import {
  BimManageIfcModelsButtonComponent,
} from 'core-app/features/bim/ifc_models/toolbar/manage-ifc-models-button/bim-manage-ifc-models-button.component';
import {
  WorkPackageCreateButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-create-button/wp-create-button.component';
import { of } from 'rxjs';
import {
  BcfImportButtonComponent,
} from 'core-app/features/bim/ifc_models/toolbar/import-export-bcf/bcf-import-button.component';
import {
  BcfExportButtonComponent,
} from 'core-app/features/bim/ifc_models/toolbar/import-export-bcf/bcf-export-button.component';
import {
  RefreshButtonComponent,
} from 'core-app/features/bim/ifc_models/toolbar/import-export-bcf/refresh-button.component';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import {
  WorkPackageSettingsButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-settings-button/wp-settings-button.component';

@Component({
  templateUrl: '../../../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    '../../../../work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
    './styles/generic.sass',
  ],
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    BcfViewService,
    QueryParamListenerService,
  ],
  selector: 'op-ifc-viewer-page',
})
export class IFCViewerPageComponent extends PartitionedQuerySpacePageComponent implements UntilDestroyedMixin, OnInit {
  text = {
    title: this.I18n.t('js.bcf.management'),
    delete: this.I18n.t('js.button_delete'),
    edit: this.I18n.t('js.button_edit'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
  };

  private readonly newRoute = this.viewerBridgeService.shouldShowViewer
    ? 'bim.partitioned.list.new'
    : 'bim.partitioned.new';

  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: WorkPackageCreateButtonComponent,
      inputs: {
        stateName$: of(this.newRoute),
        allowed: ['work_packages.createWorkPackage', 'work_package.copy'],
      },
    },
    {
      component: RefreshButtonComponent,
      show: ():boolean => !this.viewerBridgeService.shouldShowViewer,
    },
    {
      component: BcfImportButtonComponent,
      show: ():boolean => this.ifcData.allowed('manage_bcf'),
      containerClasses: 'hidden-for-tablet',
    },
    {
      component: BcfExportButtonComponent,
      show: ():boolean => this.ifcData.allowed('manage_bcf'),
      containerClasses: 'hidden-for-tablet',
    },
    {
      component: WorkPackageFilterButtonComponent,
      show: ():boolean => this.bcfView.currentViewerState() !== 'viewer',
    },
    {
      component: BcfViewToggleButtonComponent,
      containerClasses: 'hidden-for-tablet',
    },
    {
      component: ZenModeButtonComponent,
      containerClasses: 'hidden-for-tablet',
    },
    {
      component: BimManageIfcModelsButtonComponent,
      // Hide 'Manage models' toolbar button on plugin environment (ie: Revit)
      show: ():boolean => this.viewerBridgeService.shouldShowViewer
        && this.ifcData.allowed('manage_ifc_models'),
    },
    {
      component: WorkPackageSettingsButtonComponent,
      containerClasses: 'hidden-for-tablet',
      show: ():boolean => this.authorisationService.can('query', 'updateImmediately'),
      inputs: {
        hideTableOptions: true,
      },
    },
  ];

  constructor(
    readonly ifcData:IfcModelsDataService,
    readonly bcfView:BcfViewService,
    readonly injector:Injector,
    readonly viewerBridgeService:ViewerBridgeService,
  ) {
    super(injector);
  }

  ngOnInit():void {
    super.ngOnInit();

    this.setupChangeObserver(this.bcfView);

    this.querySpace.query.values$()
      .pipe(this.untilDestroyed())
      .subscribe((query) => {
        const dr = query.displayRepresentation || bcfSplitViewCardsIdentifier;
        this.filterAllowed = dr !== bcfViewerViewIdentifier;
        this.cdRef.detectChanges();
      });
  }

  /**
   * Initialize the BcfViewService when the query of the isolated space is loaded
   */
  public loadQuery(firstPage = false):Promise<QueryResource> {
    return super.loadQuery(firstPage)
      .then((query) => {
        this.bcfView.initialize(query, query.results);
        return query;
      });
  }
}
