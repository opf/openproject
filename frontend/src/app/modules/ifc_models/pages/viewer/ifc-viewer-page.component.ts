import {ChangeDetectionStrategy, Component, Injector} from "@angular/core";
import {GonService} from "core-app/modules/common/gon/gon.service";
import {
  PartitionedQuerySpacePageComponent,
  ToolbarButtonComponentDefinition
} from "core-app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component";
import {BcfImportButtonComponent} from "core-app/modules/bcf/bcf-buttons/bcf-import-button.component";
import {BcfExportButtonComponent} from "core-app/modules/bcf/bcf-buttons/bcf-export-button.component";
import {WorkPackageFilterButtonComponent} from "core-components/wp-buttons/wp-filter-button/wp-filter-button.component";
import {ZenModeButtonComponent} from "core-components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component";
import {componentDestroyed} from "ng2-rx-componentdestroyed";
import {
  bimListViewIdentifier,
  bimViewerViewIdentifier,
  BimViewService
} from "core-app/modules/ifc_models/pages/viewer/bim-view.service";
import {BimViewToggleButtonComponent} from "core-app/modules/ifc_models/toolbar/view-toggle/bim-view-toggle-button.component";
import {IfcModelsDataService} from "core-app/modules/ifc_models/pages/viewer/ifc-models-data.service";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {BimManageIfcModelsButtonComponent} from "core-app/modules/ifc_models/toolbar/manage-ifc-models-button/bim-manage-ifc-models-button.component";
import {WorkPackageCreateButtonComponent} from "core-components/wp-buttons/wp-create-button/wp-create-button.component";
import {StateService} from "@uirouter/core";

@Component({
  templateUrl: '/app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    // Absolute paths do not work for styleURLs :-(
    '../../../work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass'
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    QueryParamListenerService
  ]
})
export class IFCViewerPageComponent extends PartitionedQuerySpacePageComponent {

  text = {
    title: this.I18n.t('js.ifc_models.models.default'),
    delete: this.I18n.t('js.button_delete'),
    edit: this.I18n.t('js.button_edit'),
    areYouSure: this.I18n.t('js.text_are_you_sure')
  };

  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: WorkPackageCreateButtonComponent,
      inputs: {
      stateName: this.state.current.data.newRoute || 'bim.partitioned.split.new',
        allowed: ['work_packages.createWorkPackage', 'work_package.copy']
      }
    },
    {
      component: BcfImportButtonComponent,
      show: () => this.ifcData.allowed('manage_bcf')
    },
    {
      component: BcfExportButtonComponent,
      show: () => this.ifcData.allowed('manage_bcf')
    },
    {
      component: WorkPackageFilterButtonComponent,
      show: () => this.bimView.currentViewerState() !== bimViewerViewIdentifier
    },
    {
      component: BimViewToggleButtonComponent,
      containerClasses: 'hidden-for-mobile'
    },
    {
      component: ZenModeButtonComponent,
      containerClasses: 'hidden-for-mobile'
    },
    {
      component: BimManageIfcModelsButtonComponent,
      show: () => this.ifcData.allowed('manage_ifc_models')
    }
  ];

  constructor(readonly ifcData:IfcModelsDataService,
              readonly state:StateService,
              readonly bimView:BimViewService,
              readonly gon:GonService,
              readonly injector:Injector) {
    super(injector);
  }

  ngOnInit() {
    super.ngOnInit();

    this
      .bimView
      .observeUntil(componentDestroyed(this))
      .subscribe((view) => {
        this.filterAllowed = view !== bimViewerViewIdentifier;
      });
  }

  /**
   * We disable using the query title for now,
   * but this might be useful later.
   *
   * To re-enable query titles, remove this function.
   *
   * @param _query
   */
  updateTitle(query?:QueryResource) {
    if (this.bimView.current === bimListViewIdentifier) {
      super.updateTitle(query);
    } else if (this.ifcData.isSingleModel()) {
      this.selectedTitle = this.ifcData.models[0].name;
    } else {
      this.selectedTitle = this.I18n.t('js.ifc_models.models.default');
    }

    // For now, disable any editing
    this.titleEditingEnabled = false;
  }
}
