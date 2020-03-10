import {Injectable} from "@angular/core";
import {from, Observable} from "rxjs";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {map, tap} from "rxjs/operators";
import {Board, BoardType} from "core-app/modules/boards/board/board";
import {AuthorisationService} from "core-app/modules/common/model-auth/model-auth.service";

@Injectable({ providedIn: 'root' })
export class BoardDmService {

  constructor(protected GridDm:GridDmService,
              protected PathHelper:PathHelperService,
              protected authorisationService:AuthorisationService,
              protected CurrentProject:CurrentProjectService,
              protected halResourceService:HalResourceService) {
  }

  /**
   * Return all boards in the current scope of the project
   *
   * @param projectIdentifier
   */
  public allInScope(projectIdentifier:string|null = this.CurrentProject.identifier) {
    const path = this.boardPath(projectIdentifier);

    return from(
      this.GridDm.list({ filters: [['scope', '=', [path]]] })
    )
      .pipe(
        tap(collection => this.authorisationService.initModelAuth('boards', collection.$links)),
        map(collection => collection.elements.map(grid => new Board(grid)))
      );
  }

  /**
   * Load one board based on ID
   */
  public one(id:number):Observable<Board> {
    return from(this.GridDm.one(id))
      .pipe(
        map(grid => new Board(grid))
      );
  }

  /**
   * Save the changes to the board
   */
  public save(board:Board) {
    return this.fetchSchema(board)
      .then(schema => this.GridDm.update(board.grid, schema))
      .then(grid => {
        board.grid = grid;
        return board;
      });
  }

  private fetchSchema(board:Board) {
    return this.GridDm.updateForm(board.grid)
      .then((form) => form.schema);
  }

  /**
   * Retrieve the board path identifier for looking up grids.
   *
   * @param projectIdentifier The current project identifier
   */
  public boardPath(projectIdentifier:string|null = this.CurrentProject.identifier) {
    return this.PathHelper.projectBoardsPath(projectIdentifier);
  }

  /**
   * Create a new board
   * @param type
   * @param name
   */
  public async create(type:BoardType, name:string, actionAttribute?:string):Promise<Board> {
    return this.createGrid(type, name, actionAttribute)
      .then(grid => new Board(grid));
  }

  public delete(board:Board):Promise<unknown> {
    if (!board.grid.delete) {
      return Promise.reject("Deletion not possible");
    }

    return board.grid.delete();
  }


  private createGrid(type:BoardType, name:string, actionAttribute?:string):Promise<GridResource> {
    const path = this.boardPath();
    let payload:any = _.set({ name: name }, '_links.scope.href', path);
    payload.options = {
      type: type,
    };

    if (actionAttribute) {
      payload.options.attribute = actionAttribute;
    }

    return this.GridDm
      .createForm(payload)
      .then((form) => {
        let resource = this.halResourceService.createHalResource<GridResource>(form.payload.$source);
        return this.GridDm.create(resource, form.schema);
      });
  }

}
