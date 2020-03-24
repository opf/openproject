import {ChangeDetectionStrategy, Component, Injector} from "@angular/core";
import {GonService} from "core-app/modules/common/gon/gon.service";
import {
  PartitionedQuerySpacePageComponent,
  ToolbarButtonComponentDefinition
} from "core-app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component";
import {WorkPackageFilterButtonComponent} from "core-components/wp-buttons/wp-filter-button/wp-filter-button.component";
import {ZenModeButtonComponent} from "core-components/wp-buttons/zen-mode-toggle-button/zen-mode-toggle-button.component";
import {
  bimListViewIdentifier,
  bimViewerViewIdentifier,
  BimViewService
} from "core-app/modules/bim/ifc_models/pages/viewer/bim-view.service";
import {BimViewToggleButtonComponent} from "core-app/modules/bim/ifc_models/toolbar/view-toggle/bim-view-toggle-button.component";
import {IfcModelsDataService} from "core-app/modules/bim/ifc_models/pages/viewer/ifc-models-data.service";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {BimManageIfcModelsButtonComponent} from "core-app/modules/bim/ifc_models/toolbar/manage-ifc-models-button/bim-manage-ifc-models-button.component";
import {WorkPackageCreateButtonComponent} from "core-components/wp-buttons/wp-create-button/wp-create-button.component";
import {StateService, TransitionService} from "@uirouter/core";
import {BehaviorSubject} from "rxjs";
import {BcfImportButtonComponent} from "core-app/modules/bim/ifc_models/toolbar/import-export-bcf/bcf-import-button.component";
import {BcfExportButtonComponent} from "core-app/modules/bim/ifc_models/toolbar/import-export-bcf/bcf-export-button.component";
import {componentDestroyed} from "@w11k/ngx-componentdestroyed";

@Component({
  templateUrl: '/app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.html',
  styleUrls: [
    '/app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass'
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    QueryParamListenerService,
  ]
})
export class IFCViewerPageComponent extends PartitionedQuerySpacePageComponent {

  text = {
    title: this.I18n.t('js.ifc_models.models.default'),
    delete: this.I18n.t('js.button_delete'),
    edit: this.I18n.t('js.button_edit'),
    areYouSure: this.I18n.t('js.text_are_you_sure')
  };

  newRoute$ = new BehaviorSubject<string>(this.state.current.data.newRoute);
  transitionUnsubscribeFn:Function;

  toolbarButtonComponents:ToolbarButtonComponentDefinition[] = [
    {
      component: WorkPackageCreateButtonComponent,
      inputs: {
        stateName$: this.newRoute$,
        allowed: ['work_packages.createWorkPackage', 'work_package.copy']
      }
    },
    {
      component: BcfImportButtonComponent,
      show: () => this.ifcData.allowed('manage_bcf'),
      containerClasses: 'hidden-for-mobile'
    },
    {
      component: BcfExportButtonComponent,
      show: () => this.ifcData.allowed('manage_bcf'),
      containerClasses: 'hidden-for-mobile'
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
              readonly transition:TransitionService,
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

    // Keep the new route up to date depending on where we move to
    this.transitionUnsubscribeFn = this.transition.onSuccess({}, () => {
      this.newRoute$.next(this.state.current.data.newRoute);
    });
  }

  /**
   * We disable using the query title for now,
   * but this might be useful later.
   *
   * To re-enable query titles, remove this function.
   *
   * @param query
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
