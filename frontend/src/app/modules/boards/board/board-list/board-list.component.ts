import {AfterViewInit, Component, ElementRef, Input, OnInit, ViewChild} from "@angular/core";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";
import {Board} from "core-app/modules/boards/board/board";

@Component({
  selector: 'board-list',
  templateUrl: './board-list.component.html',
  styleUrls: ['./board-list.component.sass']
})
export class BoardListComponent implements AfterViewInit {
  @Input() queryId:number;

  @ViewChild('loadingIndicator') indicator:ElementRef;

  /** The query resoure being loaded */
  public query:QueryResource;

  constructor(private readonly QueryDm:QueryDmService,
              private readonly loadingIndicator:LoadingIndicatorService,
              private readonly CurrentProject:CurrentProjectService) {
  }

  ngAfterViewInit():void {
    this.loadingPromise = this.QueryDm.find({}, this.queryId)
      .then(query => {
        this.query = query;
      });
  }

  get columnsQueryProps() {
    return  {
      'columns[]': ['id', 'subject'],
      'showHierarchies': false,
      'pageSize': 500,
    };
  }

  get boardTableConfiguration():WorkPackageTableConfigurationObject {
    return {
      hierarchyToggleEnabled: false,
      columnMenuEnabled: false,
      actionsColumnEnabled: false,
      isEmbedded: true
    };
  }

  private set loadingPromise(promise:Promise<unknown>) {
    const indicator = jQuery(this.indicator.nativeElement);
    this.loadingIndicator.indicator(indicator).promise = promise;
  }
}
