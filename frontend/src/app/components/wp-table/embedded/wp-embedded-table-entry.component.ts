import {AfterViewInit, Component, ElementRef, Injector, Input, OnDestroy, OnInit} from '@angular/core';
import {CurrentProjectService} from '../../projects/current-project.service';
import {TableState} from '../table-state/table-state';
import {WorkPackageStatesInitializationService} from '../../wp-list/wp-states-initialization.service';
import {WorkPackageTableRelationColumnsService} from 'core-components/wp-fast-table/state/wp-table-relation-columns.service';
import {WorkPackageTableHierarchiesService} from 'core-components/wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableTimelineService} from 'core-components/wp-fast-table/state/wp-table-timeline.service';
import {WorkPackageTablePaginationService} from 'core-components/wp-fast-table/state/wp-table-pagination.service';
import {WorkPackageTableGroupByService} from 'core-components/wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableSortByService} from 'core-components/wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableFiltersService} from 'core-components/wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableColumnsService} from 'core-components/wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableSumService} from 'core-components/wp-fast-table/state/wp-table-sum.service';
import {WorkPackageTableAdditionalElementsService} from 'core-components/wp-fast-table/state/wp-table-additional-elements.service';
import {withLatestFrom} from 'rxjs/operators';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {
  WorkPackageTableConfiguration,
  WorkPackageTableConfigurationObject
} from 'core-components/wp-table/wp-table-configuration';
import {OpTableActionFactory} from 'core-components/wp-table/table-actions/table-action';
import {WorkPackageTableRefreshService} from 'core-components/wp-table/wp-table-refresh-request.service';
import {OpTableActionsService} from 'core-components/wp-table/table-actions/table-actions.service';
import {LoadingIndicatorService} from 'core-app/modules/common/loading-indicator/loading-indicator.service';
import {WorkPackageTableSelection} from 'core-components/wp-fast-table/state/wp-table-selection.service';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {QueryDmService} from 'core-app/modules/hal/dm-services/query-dm.service';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {UrlParamsHelperService} from 'core-components/wp-query/url-params-helper';
import {WpTableConfigurationModalComponent} from 'core-components/wp-table/configuration-modal/wp-table-configuration.modal';
import {OpModalService} from 'core-components/op-modals/op-modal.service';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Component({
  selector: 'wp-embedded-table-entry',
  template: `
    <wp-embedded-table [queryProps]="queryProps"
                       [configuration]="configuration">
    </wp-embedded-table>
  `
})
export class WorkPackageEmbeddedTableEntryComponent implements OnInit {
  public queryProps:any;
  public configuration:any;

  constructor(readonly elementRef:ElementRef) {
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    this.queryProps = JSON.parse(element.getAttribute('query-props'));
    this.configuration = JSON.parse(element.getAttribute('configuration'));
  }
}

DynamicBootstrapper.register({ selector: 'wp-embedded-table-entry', cls: WorkPackageEmbeddedTableEntryComponent });
