import {Injectable} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";

@Injectable()
export class BoardListService {
  public getActionAttributeValue(board:Board, query:QueryResource) {
    const attribute = board.actionAttribute!;
    const filter = _.find(query.filters, f => f.id === attribute);

    if (!(filter && filter.values[0] instanceof HalResource)) {
      return '';
    }
    const value = filter.values[0] as HalResource;
    return value;
  }
}

