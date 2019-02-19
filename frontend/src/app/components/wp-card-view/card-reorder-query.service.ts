import {Injectable} from "@angular/core";
import {TableState} from "core-components/wp-table/table-state/table-state";
import {ReorderQueryService} from "core-app/modules/boards/drag-and-drop/reorder-query.service";

@Injectable()
export class CardReorderQueryService extends ReorderQueryService {

  protected getCurrentOrder(tableState:TableState):string[] {
    return tableState
      .results
      .mapOr((results) => results.elements.map(el => el.id.toString()), []);
  }
}
