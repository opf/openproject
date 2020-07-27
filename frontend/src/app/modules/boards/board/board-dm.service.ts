import {Injectable} from "@angular/core";
import {Observable} from "rxjs";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {map, switchMap, tap} from "rxjs/operators";
import {Board, BoardType} from "core-app/modules/boards/board/board";
import {AuthorisationService} from "core-app/modules/common/model-auth/model-auth.service";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";

@Injectable({ providedIn: 'root' })
export class BoardDmService {

  constructor(protected apiV3Service:APIV3Service,
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
  public allInScope(projectIdentifier:string|null = this.CurrentProject.identifier):Observable<Board[]> {
    const path = this.boardPath(projectIdentifier);

    return this
      .apiV3Service
      .grids
      .list({ filters: [['scope', '=', [path]]] })
      .pipe(
        tap(collection => this.authorisationService.initModelAuth('boards', collection.$links)),
        map(collection => collection.elements.map(grid => new Board(grid)))
      );
  }

  /**
   * Load one board based on ID
   */
  public one(id:number):Observable<Board> {
    return this
      .apiV3Service
      .grids
      .id(id)
      .get()
      .pipe(
        map(grid => new Board(grid))
      );
  }

  /**
   * Save the changes to the board
   */
  public save(board:Board):Observable<Board> {
    return this
      .fetchSchema(board)
      .pipe(
        switchMap((schema:SchemaResource) => this
          .apiV3Service
          .grids
          .id(board.grid)
          .patch(board.grid, schema)
        ),
        map(grid => {
          board.grid = grid;
          return board;
        })
      );
  }

  private fetchSchema(board:Board):Observable<SchemaResource> {
    return this
      .apiV3Service
      .grids
      .id(board.grid)
      .form
      .post({})
      .pipe(
        map(form => form.schema)
      );
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
  public create(type:BoardType, name:string, actionAttribute?:string):Observable<Board> {
    return this
      .createGrid(type, name, actionAttribute)
      .pipe(
        map(grid => new Board(grid))
      );
  }

  public delete(board:Board):Promise<unknown> {
    if (!board.grid.delete) {
      return Promise.reject("Deletion not possible");
    }

    return board.grid.delete();
  }


  private createGrid(type:BoardType, name:string, actionAttribute?:string):Observable<GridResource> {
    const path = this.boardPath();
    let payload:any = _.set({ name: name }, '_links.scope.href', path);
    payload.options = {
      type: type,
    };

    if (actionAttribute) {
      payload.options.attribute = actionAttribute;
    }

    return this
      .apiV3Service
      .grids
      .form
      .post(payload)
      .pipe(
        switchMap((form) => {
          return this
            .apiV3Service
            .grids
            .post(form.payload.$source);
        })
      );
  }

}
