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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, OnInit, ViewEncapsulation, inject } from '@angular/core';
import { distinctUntilChanged, map } from 'rxjs/operators';

import {
  PartitionedQuerySpacePageComponent,
  ToolbarButtonComponentDefinition,
  ViewPartitionState,
} from 'core-app/features/work-packages/routing/partitioned-query-space-page/partitioned-query-space-page.component';
import {
  WorkPackageFilterButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/wp-filter-button/wp-filter-button.component';
import {
  ZenModeButtonComponent,
} from 'core-app/features/work-packages/components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component';
import {
  bcfCardsViewIdentifier,
  bcfSplitViewCardsIdentifier,
  bcfTableViewIdentifier,
  bcfViewerViewIdentifier,
  BcfViewService,
  BcfViewState,
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
  templateUrl: '../../../../work-packages/routing/partitioned-query-space-page/primerized-partitioned-query-space-page.component.html',
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
  standalone: false,
})
export class IFCViewerPageComponent
  extends PartitionedQuerySpacePageComponent
  implements UntilDestroyedMixin, OnInit {
  readonly ifcData = inject(IfcModelsDataService);
  readonly bcfView = inject(BcfViewService);
  readonly viewerBridgeService = inject(ViewerBridgeService);

  text = {
    title: this.I18n.t('js.bcf.management'),
    delete: this.I18n.t('js.button_delete'),
    edit: this.I18n.t('js.button_edit'),
    areYouSure: this.I18n.t('js.text_are_you_sure'),
  };

  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: WorkPackageCreateButtonComponent,
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

  ngOnInit():void {
    super.ngOnInit();

    this.setupChangeObserver(this.bcfView);

    this.querySpace.query.values$()
      .pipe(this.untilDestroyed())
      .subscribe((query) => {
        const dr = query.displayRepresentation ?? bcfSplitViewCardsIdentifier;
        this.filterAllowed = dr !== bcfViewerViewIdentifier;
        // When changing the query space by selecting a dropdown option, handle the split screen
        // and hide it for full views.
        this.updateSplitScreen(dr as BcfViewState);
        this.cdRef.detectChanges();
      });

    // When going back from "details" route to "list" route, handle the split screen right side.
    // Scoped to actual route transitions (distinctUntilChanged on the details/list boolean),
    // not every URL change - a filter-only query-param update also fires `changed$`, and at
    // that point the query for the new filter hasn't reloaded yet, so `displayRepresentation`
    // would read as stale/undefined and wrongly collapse the split screen for good (there's no
    // code path that ever widens it back once collapsed).
    this.urlParams.changed$
      .pipe(
        map(() => this.urlParams.currentDetailsRouteParams() !== null),
        distinctUntilChanged(),
        this.untilDestroyed(),
      )
      .subscribe((isDetailsRoute):void => {
        if (isDetailsRoute) {
          return;
        }

        const dr = this.querySpace.query.value?.displayRepresentation ?? bcfSplitViewCardsIdentifier;
        this.updateSplitScreen(dr as BcfViewState);
      });
  }

  /**
   * Neither the plain browser nor the Revit add-in route through a uiRouter '.details'/'.new'
   * sub-state anymore (the split view/create form render via a Rails Turbo frame instead), so
   * the partition is derived from the URL rather than from state data.
   */
  protected override setPartition():void {
    const partition:ViewPartitionState = window.location.pathname.includes('/details/') ? '-split' : '-left-only';
    this.currentPartition = partition;
  }

  breadcrumbItems() {
    return [
      {
        href: this.pathHelperService.projectPath(this.currentProject.identifier!),
        text: (this.currentProject.name),
      },
      {
        href: this.pathHelperService.projectBCFPath(this.currentProject.identifier!),
        text: this.I18n.t('js.bcf.label_bcf'),
      },
      this.selectedTitle ?? '',
    ];
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

  /**
   * Tracks whether *this* method is the one that last collapsed the split screen
   * width to 0, so it only ever restores a width it collapsed itself - never a
   * width the user set by hand via the resizer (WpResizerComponent shares the
   * same --split-screen-width CSS variable for the WP details pane).
   */
  private collapsedSplitScreenWidth = false;

  private updateSplitScreen(dr:BcfViewState):void {
    const isFullViewDisplayRepresentation = [
      bcfViewerViewIdentifier,
      bcfCardsViewIdentifier,
      bcfTableViewIdentifier,
    ].includes(dr);

    const isListRoute = !window.location.pathname.includes('/details/');

    if (isListRoute && isFullViewDisplayRepresentation) {
      document.documentElement.style.setProperty('--split-screen-width', '0');
      this.collapsedSplitScreenWidth = true;
    } else if (this.collapsedSplitScreenWidth) {
      // Restore the user's own resized width (WpResizerComponent's own
      // localStorage-backed preference, shared across all --split-screen-width
      // resizers) rather than falling back to the CSS default - otherwise the
      // resizer's cached in-memory width goes stale relative to the (wrongly
      // reset) rendered width, only surfacing at the next resize's own re-sync
      // as an apparent "jump back to default" right as dragging starts.
      const savedWidth = window.OpenProject.guardedLocalStorage('openProject-splitViewFlexBasis');
      if (savedWidth) {
        document.documentElement.style.setProperty('--split-screen-width', `${savedWidth}px`);
      } else {
        document.documentElement.style.removeProperty('--split-screen-width');
      }
      this.collapsedSplitScreenWidth = false;
    }
  }
}
