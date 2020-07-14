import {Injectable} from "@angular/core";
import {Board} from "core-app/modules/boards/board/board";
import {StatusResource} from "core-app/modules/hal/resources/status-resource";
import {BoardActionService} from "core-app/modules/boards/board/board-actions/board-action.service";

@Injectable()
export class BoardStatusActionService extends BoardActionService {
  filterName = 'status';

  public get localizedName() {
    return this.I18n.t('js.work_packages.properties.status');
  }

  public addActionQueries(board:Board):Promise<Board> {
    return this.withLoadedAvailable()
      .then((results) =>
        Promise.all<unknown>(
          results.map((status:StatusResource) => {

            if (status.isDefault) {
              return this.addActionQuery(board, status);
            }

            return Promise.resolve(board);
          })
        )
          .then(() => board)
      );
  }

  public warningTextWhenNoOptionsAvailable() {
    return Promise.resolve(this.I18n.t('js.boards.add_list_modal.warning.status'));
  }

  protected loadAvailable():Promise<StatusResource[]> {
    return this
      .apiV3Service
      .statuses
      .get()
      .toPromise()
      .then(collection => collection.elements);
  }

}
