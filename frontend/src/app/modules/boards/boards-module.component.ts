import {Component, OnInit} from "@angular/core";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";

@Component({
  selector: 'boards-module',
  templateUrl: './boards-module.component.html',
  styleUrls: ['./boards-module.component.sass']
})
export class BoardsModuleComponent implements OnInit {

  public queries:QueryResource[];

  constructor(private readonly QueryDm:QueryDmService,
              private readonly loadingIndicator:LoadingIndicatorService,
              private readonly CurrentProject:CurrentProjectService) {
  }

  ngOnInit():void {
    this.loadingPromise = this.QueryDm.all(this.CurrentProject.identifier)
      .toPromise()
      .then((queries) => {
        this.queries = _.take(queries.elements, 3);
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
    this.loadingIndicator.indicator('boards-module').promise = promise;
  }
}

DynamicBootstrapper.register({
  selector: 'boards-module',
  cls: BoardsModuleComponent
});
