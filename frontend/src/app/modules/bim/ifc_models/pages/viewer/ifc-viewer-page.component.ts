import {
  ChangeDetectionStrategy, ChangeDetectorRef,
  Component,
  Injector,
  OnDestroy,
  ViewEncapsulation
} from "@angular/core";
import {GonService} from "core-app/modules/common/gon/gon.service";
import {
  DynamicComponentDefinition,
  ToolbarButtonComponentDefinition, ViewPartitionState
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
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {Ng2StateDeclaration} from "@uirouter/angular";
import {take} from "rxjs/operators";
import {QuerySpaceService} from "core-app/modules/query-space/services/query-space/query-space.service";
import {WorkPackageStaticQueriesService} from "core-components/wp-query-select/wp-static-queries.service";
import {AuthorisationService} from "core-app/modules/common/model-auth/model-auth.service";
import {OpTitleService} from "core-components/html/op-title.service";
import {WorkPackageFilterContainerComponent} from "core-components/filters/filter-container/filter-container.directive";
import {UIRouterGlobals} from '@uirouter/core';
import {ViewerBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";

@Component({
  templateUrl: './ifc-viewer-page.component.html',
  styleUrls: [
    '/app/modules/work_packages/routing/partitioned-query-space-page/partitioned-query-space-page.component.sass',
    './styles/generic.sass'
  ],
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    QueryParamListenerService,
  ]
})
export class IFCViewerPageComponent extends UntilDestroyedMixin implements OnDestroy {
  text = {
    title: this.I18n.t('js.ifc_models.models.default'),
    delete: this.I18n.t('js.button_delete'),
    edit: this.I18n.t('js.button_edit'),
    areYouSure: this.I18n.t('js.text_are_you_sure')
  };

  newRoute$ = new BehaviorSubject<string>(this.uIRouterGlobals.current.data.newRoute);

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
      show: () => {
        // Hide 'Manage models' toolbar button on plugin environment (ie: Revit)
        return this.viewerBridgeService.shouldShowViewer &&
               this.ifcData.allowed('manage_ifc_models');
      }
    }
  ];

  /** Determine when query is initially loaded */
  showToolbar = false;
  /** Listener callbacks */
  removeTransitionSubscription:Function;
  /** We need to pass the correct partition state to the view to manage the grid */
  currentPartition:ViewPartitionState = '-split';
  /** Current query title to render */
  selectedTitle?:string;
  /** Which filter container component to mount */
  filterContainerDefinition:DynamicComponentDefinition = {
    component: WorkPackageFilterContainerComponent
  };
  /** Go back to list using back-button */
  backButtonCallback = () => this.$state.go('bim');

  constructor(readonly ifcData:IfcModelsDataService,
              readonly bimView:BimViewService,
              readonly transition:TransitionService,
              readonly gon:GonService,
              readonly injector:Injector,
              readonly I18n:I18nService,
              readonly $state:StateService,
              readonly $transitions:TransitionService,
              readonly querySpaceService:QuerySpaceService,
              readonly wpStaticQueries:WorkPackageStaticQueriesService,
              readonly authorisationService:AuthorisationService,
              readonly titleService:OpTitleService,
              readonly changeDetectorRef:ChangeDetectorRef,
              readonly uIRouterGlobals:UIRouterGlobals,
              readonly viewerBridgeService:ViewerBridgeService) {
    super();
  }

  ngOnInit() {
    this.setPartition(this.uIRouterGlobals.current);
    this.removeTransitionSubscription = this.$transitions.onSuccess({}, (transition):any => {
      const toState = transition.to();

      this.setPartition(toState);
      // Keep the new route up to date depending on where we move to
      this.newRoute$.next(this.uIRouterGlobals.current.data.newRoute);
    });

    // Mark tableInformationLoaded when initially loading done
    this.setupInformationLoadedListener();

    this.querySpaceService.query.query.values$().pipe(
      this.untilDestroyed()
    ).subscribe((query) => {
      // Update the title whenever the query changes
      this.updateTitle(query);
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
      // Too early for loaded query
      if (!query) {
        return;
      }

      if (query.persisted) {
        this.selectedTitle = query.name;
      } else {
        this.selectedTitle = this.wpStaticQueries.getStaticName(query);
      }

      // Update the title if we're in the list state alone
      this.titleService.setFirstPart(this.selectedTitle);
    } else if (this.ifcData.isSingleModel()) {
      this.selectedTitle = this.ifcData.models[0].name;
    } else {
      this.selectedTitle = this.I18n.t('js.ifc_models.models.default');
    }
  }

  ngOnDestroy():void {
    this.removeTransitionSubscription();
  }

  /**
   * We need to set the current partition to the grid to ensure
   * either side gets expanded to full width if we're not in '-split' mode.
   *
   * @param state The current or entering state
   */
  protected setPartition(state:Ng2StateDeclaration) {
    this.currentPartition = (state.data && state.data.partition) ? state.data.partition : '-split';
  }

  protected setupInformationLoadedListener() {
    this
      .querySpaceService
      .query
      .initialized
      .values$()
      .pipe(take(1))
      .subscribe(() => {
        this.showToolbar = true;
        this.changeDetectorRef.detectChanges();
      });
  }
}
