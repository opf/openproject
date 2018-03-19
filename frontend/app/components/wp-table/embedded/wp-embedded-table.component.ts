import {AfterViewInit, Component, Input, OnDestroy, OnInit} from '@angular/core';
import {QueryDmService} from '../../api/api-v3/hal-resource-dms/query-dm.service';
import {CurrentProjectService} from '../../projects/current-project.service';
import {
  QueryResource,
  QueryResourceInterface
} from '../../api/api-v3/hal-resources/query-resource.service';
import {TableState} from '../table-state/table-state';
import {WorkPackageStatesInitializationService} from '../../wp-list/wp-states-initialization.service';

@Component({
  selector: 'wp-embedded-table',
  template: require('!!raw-loader!./wp-embedded-table.html'),
  providers: [TableState]
})
export class WorkPackageEmbeddedTableComponent implements OnInit, OnDestroy {
  @Input('queryId') public queryId:string;

  private query:QueryResourceInterface;
  public tableInformationLoaded = false;

  constructor(readonly QueryDm:QueryDmService,
              readonly wpStatesInitialization:WorkPackageStatesInitializationService,
              readonly currentProject:CurrentProjectService) {

  }

  ngOnInit():void {
    this.loadQuery().then((query:QueryResourceInterface) => {
      this.wpStatesInitialization.initializeTable(query, query.results);
    });
  }

  ngOnDestroy():void {
  }

  private loadQuery():Promise<QueryResourceInterface> {
    return this.QueryDm.find(
      {},
      this.queryId,
      this.currentProject.identifier || undefined
    );
  }

}
