import {Injectable} from "@angular/core";
import {Observable, of} from "rxjs";
import {BoardListsService} from "core-app/modules/boards/board/board-list/board-lists.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {PayloadDmService} from "core-app/modules/hal/dm-services/payload-dm.service";
import {StateCacheService} from "core-components/states/state-cache.service";
import {BoardResource} from "core-app/modules/boards/board/board-resource";
import {multiInput, MultiInputState} from "reactivestates";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";

@Injectable()
export class BoardService {

  constructor(protected GridDm:GridDmService,
              protected PathHelper:PathHelperService,
              protected CurrentProject:CurrentProjectService,
              protected BoardsList:BoardListsService) {
  }

  /**
   * Return all boards in the current scope of the project
   *
   * @param projectIdentifier
   */
  public allInScope(projectIdentifier:string|null = this.CurrentProject.identifier) {
    const path = this.boardPath(projectIdentifier);

    return this.GridDm
      .list({ filters: [['page', '=', [path]]] })
      .then(collection => collection.elements);
  }

  /**
   * Retrive the board path identifier for looking up grids.
   *
   * @param projectIdentifier The current project identifier
   */
  public boardPath(projectIdentifier:string|null = this.CurrentProject.identifier) {
    return this.PathHelper.projectBoardsPath(projectIdentifier);
  }

  public create(name:string = 'New board'):Promise<BoardResource> {
    let payload = {
      '_links': {
        'page': {
          'href': this.pathHelper.myPagePath()
        }
      }
    };

      this
        .gridDm
        .createForm(payload)
        .then((form) => {
          let source = form.payload.$source;

          let resource = this.halResourceService.createHalResource(source) as GridResource;

          this.gridDm.create(resource, form.schema)
            .then((resource) => {
              resolve(resource);
            })
            .catch(() => {
              reject();
            });
    });


    return this.BoardsList
      .create()
      .then(query => {
        const id:number = _.max(this.boards.map(b => b.id)) || 0;
        const board = new BoardResource(id + 1, name, [query]);
        this.boards.push(board);

        return board;
      });
  }
}
