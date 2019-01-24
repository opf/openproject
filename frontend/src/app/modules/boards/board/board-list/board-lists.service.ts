import {Injectable} from "@angular/core";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {QueryFormDmService} from "core-app/modules/hal/dm-services/query-form-dm.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";

@Injectable()
export class BoardListsService {

  private readonly v3 = this.pathHelper.api.v3;

  constructor(private readonly CurrentProject:CurrentProjectService,
              private readonly pathHelper:PathHelperService,
              private readonly QueryDm:QueryDmService,
              private readonly QueryFormDm:QueryFormDmService) {

  }

  public create(name:string = 'New board'):Promise<QueryResource> {
    return this.QueryFormDm
      .loadWithParams(
        { pageSize: 0},
        undefined,
        this.CurrentProject.identifier,
        this.buildQueryRequest(name)
      )
      .then(form => {
        const query = this.QueryFormDm.buildQueryResource(form);
        return this.QueryDm.create(query, form);
      });
  }

  private buildQueryRequest(name:string) {
    return {
      'name': name,
      filters:
        [
          {
            "_type": "QueryFilter",
            "_links": {
              "filter": {
                "href": this.v3.resource("/queries/filters/manualSort")
              },
              "schema": {
                "href": this.v3.resource("/queries/filter_instance_schemas/manualSort")
              },
              "operator": {
                "href": this.v3.resource("/queries/operators/ow")
              },
              "values": []
            }
          }
        ],
      "_links":
        {
          "sortBy": [{ "href": this.v3.resource("/queries/sort_bys/manualSorting-asc") }]
        }
    };
  }
}

