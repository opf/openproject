import {ChangeDetectorRef, Component, Injector, OnInit} from "@angular/core";
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {TableState} from "core-components/wp-table/table-state/table-state";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {QueryColumn} from "app/components/wp-query/query-column";
import {combine} from "reactivestates/dist";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageEmbeddedTableComponent} from "core-components/wp-table/embedded/wp-embedded-table.component";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {UrlParamsHelperService} from "app/components/wp-query/url-params-helper";
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {WorkPackageStatesInitializationService} from "core-components/wp-list/wp-states-initialization.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {OpTableActionsService} from "core-components/wp-table/table-actions/table-actions.service";
import {WorkPackageEmbeddedBaseComponent} from "core-components/wp-table/embedded/wp-embedded-base.component";
import {WorkPackageTableTimelineService} from "core-components/wp-fast-table/state/wp-table-timeline.service";
import {WorkPackageTablePaginationService} from "core-components/wp-fast-table/state/wp-table-pagination.service";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WorkPackageTableRelationColumnsService} from "core-components/wp-fast-table/state/wp-table-relation-columns.service";
import {WorkPackageTableHierarchiesService} from "core-components/wp-fast-table/state/wp-table-hierarchy.service";
import {WorkPackageTableGroupByService} from "core-components/wp-fast-table/state/wp-table-group-by.service";
import {WorkPackageTableFiltersService} from "core-components/wp-fast-table/state/wp-table-filters.service";
import {WorkPackageTableColumnsService} from "core-components/wp-fast-table/state/wp-table-columns.service";
import {WorkPackageTableSortByService} from "core-components/wp-fast-table/state/wp-table-sort-by.service";
import {WorkPackageTableSelection} from "core-components/wp-fast-table/state/wp-table-selection.service";
import {WorkPackageTableSumService} from "core-components/wp-fast-table/state/wp-table-sum.service";
import {WorkPackageTableAdditionalElementsService} from "core-components/wp-fast-table/state/wp-table-additional-elements.service";
import {WorkPackageTableRefreshService} from "core-components/wp-table/wp-table-refresh-request.service";
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";
import {WorkPackageCreateService} from "core-components/wp-new/wp-create.service";
import {WorkPackageTableConfiguration} from "core-components/wp-table/wp-table-configuration";


@Component({
  selector: 'wp-card-view',
  templateUrl: './wp-card-view.component.html',
  providers: [
    TableState,
    OpTableActionsService,
    WorkPackageInlineCreateService,
    WorkPackageTableRelationColumnsService,
    WorkPackageTablePaginationService,
    WorkPackageTableGroupByService,
    WorkPackageTableHierarchiesService,
    WorkPackageTableSortByService,
    WorkPackageTableColumnsService,
    WorkPackageTableFiltersService,
    WorkPackageTableTimelineService,
    WorkPackageTableSelection,
    WorkPackageTableSumService,
    WorkPackageTableAdditionalElementsService,
    WorkPackageTableRefreshService,
    WorkPackageTableHighlightingService,
    { provide: IWorkPackageCreateServiceToken, useClass: WorkPackageCreateService },
    // Order is important here, to avoid this service
    // getting global injections
    WorkPackageStatesInitializationService,
  ]
})
export class WorkPackageCardViewComponent extends WorkPackageEmbeddedTableComponent implements OnInit {
  public query:QueryResource;
  public workPackages:any[];
  public columns:QueryColumn[];
  public availableColumns:QueryColumn[];
  public text:any = {
    wp_id_added_by: this.I18n.t('js.label_wp_id_added_by', {id: '', author: ''})
  };

  constructor(readonly QueryDm:QueryDmService,
              readonly tableState:TableState,
              readonly injector:Injector,
              readonly opModalService:OpModalService,
              readonly I18n:I18nService,
              readonly urlParamsHelper:UrlParamsHelperService,
              readonly loadingIndicatorService:LoadingIndicatorService,
              readonly tableActionsService:OpTableActionsService,
              readonly wpTableTimeline:WorkPackageTableTimelineService,
              readonly wpTablePagination:WorkPackageTablePaginationService,
              readonly wpStatesInitialization:WorkPackageStatesInitializationService,
              readonly currentProject:CurrentProjectService,
              readonly cdRef:ChangeDetectorRef) {
    super(QueryDm,
          tableState,
          injector,
          opModalService,
          I18n,
          urlParamsHelper,
          loadingIndicatorService,
          tableActionsService,
          wpTableTimeline,
          wpTablePagination,
          wpStatesInitialization,
          currentProject);
  }

  ngOnInit() {
    super.ngOnInit();

    this.text.wp_id_added_by = (wp:WorkPackageResource) =>
     this.I18n.t('js.label_wp_id_added_by', {id: wp.id, author: wp.author.name});

    combine(
      this.tableState.columns,
      this.tableState.results
    )
    .values$()
    .pipe(
      untilComponentDestroyed(this)
    )
    .subscribe(([columns, results]) => {
      this.workPackages = results.$embedded.elements;
      console.log(this.workPackages);

      this.columns = columns.current;
      this.availableColumns = this.columns.filter(function (column) {
        return column.id != 'id' && column.id != 'subject' && column.id != 'author';
      });
      console.log(this.availableColumns);

      this.cdRef.detectChanges();
    });
  }

  ngOnDestroy():void {

  }
}
