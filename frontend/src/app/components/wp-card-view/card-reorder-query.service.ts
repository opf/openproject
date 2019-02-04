import {Injectable} from "@angular/core";
import {TableState} from "core-components/wp-table/table-state/table-state";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {ReorderQueryService} from "core-app/modules/boards/drag-and-drop/reorder-query.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";

@Injectable()
export class CardReorderQueryService extends ReorderQueryService {

  protected getCurrentOrder(tableState:TableState):string[] {
    return tableState
      .results
      .mapOr((results) => results.elements.map(el => el.id.toString()), []);
  }
}
