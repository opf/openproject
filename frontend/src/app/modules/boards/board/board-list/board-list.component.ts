import {Component, ElementRef, Input, OnInit, ViewChild} from "@angular/core";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {
  LoadingIndicatorService,
  withLoadingIndicator
} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";
import {Observable, of} from "rxjs";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

@Component({
  selector: 'board-list',
  templateUrl: './board-list.component.html',
  styleUrls: ['./board-list.component.sass']
})
export class BoardListComponent implements OnInit {
  @Input() queryInput:number|QueryResource;

  @ViewChild('loadingIndicator') indicator:ElementRef;

  /** The query resource being loaded */
  public query$:Observable<QueryResource>;

  constructor(private readonly QueryDm:QueryDmService,
              private readonly loadingIndicator:LoadingIndicatorService) {
  }

  ngOnInit():void {
    if (this.queryInput instanceof HalResource) {
      this.query$ = of(this.queryInput);
      return;
    }

    this.query$ = this.QueryDm
      .stream(this.columnsQueryProps, this.queryInput)
      .pipe(
        withLoadingIndicator(this.indicatorInstance, 50)
      );
  }

  get columnsQueryProps() {
    return {
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
      dragAndDropEnabled: true,
      isEmbedded: true
    };
  }

  private get indicatorInstance() {
    return this.loadingIndicator.indicator(jQuery(this.indicator.nativeElement));
  }
}
