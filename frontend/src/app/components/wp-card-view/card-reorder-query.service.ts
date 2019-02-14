import {Injectable} from "@angular/core";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {ReorderQueryService} from "core-app/modules/boards/drag-and-drop/reorder-query.service";

@Injectable()
export class CardReorderQueryService extends ReorderQueryService {

  protected getCurrentOrder(querySpace:IsolatedQuerySpace):string[] {
    return querySpace
      .results
      .mapOr((results) => results.elements.map(el => el.id.toString()), []);
  }
}
