import {ChangeDetectionStrategy, Component, Injector} from "@angular/core";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
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
import {bimViewerViewIdentifier, BimViewService} from "core-app/modules/ifc_models/pages/viewer/bim-view.service";
import {BimViewToggleButtonComponent} from "core-app/modules/ifc_models/toolbar/view-toggle/bim-view-toggle-button.component";
import {IfcModelsDataService} from "core-app/modules/ifc_models/pages/viewer/ifc-models-data.service";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";

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
      component: BcfImportButtonComponent,
    },
    {
      component: BcfExportButtonComponent,
    },
    {
      component: WorkPackageFilterButtonComponent
    },
    {
      component: BimViewToggleButtonComponent,
      containerClasses: 'hidden-for-mobile'
    },
    {
      component: ZenModeButtonComponent,
      containerClasses: 'hidden-for-mobile'
    }
  ];

  constructor(readonly ifcData:IfcModelsDataService,
              readonly bimView:BimViewService,
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

  public get title() {
    if (this.$state.includes('bim.space.defaults')) {
      return this.I18n.t('js.ifc_models.models.default');
    } else {
      return this.ifcData.models[0]['name'];
    }
  }

  /** We do not have a mapping for html title in this module yet */
  protected shouldUpdateHtmlTitle():boolean {
    return false;
  }
}
