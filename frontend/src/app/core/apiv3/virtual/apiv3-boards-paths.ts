//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { Observable } from 'rxjs';
import { ApiV3ListParameters, listParamsString } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { Board, BoardType } from 'core-app/features/boards/board/board';
import { map, switchMap, tap } from 'rxjs/operators';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { ApiV3Collection } from 'core-app/core/apiv3/cache/cachable-apiv3-collection';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3BoardPath } from 'core-app/core/apiv3/virtual/apiv3-board-path';
import { StateCacheService } from 'core-app/core/apiv3/cache/state-cache.service';
import { MAGIC_PAGE_NUMBER } from 'core-app/core/apiv3/helpers/get-paginated-results';

export class ApiV3BoardsPaths extends ApiV3Collection<Board, ApiV3BoardPath> {
  @InjectField() private authorisationService:AuthorisationService;

  @InjectField() private PathHelper:PathHelperService;

  constructor(protected apiRoot:ApiV3Service,
    protected basePath:string) {
    super(apiRoot, basePath, 'grids', ApiV3BoardPath);
  }

  /**
   * Load a list of grids with a given list parameter filter
   * @param params
   */
  public list(params?:ApiV3ListParameters):Observable<Board[]> {
    return this
      .halResourceService
      .get<CollectionResource<GridResource>>(this.path + listParamsString(params))
      .pipe(
        tap((collection) => this.authorisationService.initModelAuth('boards', collection.$links)),
        map((collection) => collection.elements.map((grid) => {
          const board = new Board(grid);
          board.sortWidgets();
          this.touch(board);

          return board;
        })),
      );
  }

  /**
   * Return all boards in the current scope of the project
   *
   * @param projectIdentifier
   */
  public allInScope(projectIdentifier:string):Observable<Board[]> {
    const path = this.boardPath(projectIdentifier);
    return this.list({ filters: [['scope', '=', [path]]], pageSize: MAGIC_PAGE_NUMBER });
  }

  /**
   * Create a new board
   * @param type
   * @param name
   * @param projectIdentifier
   */
  public create(type:BoardType, name:string, projectIdentifier:string, actionAttribute?:string):Observable<Board> {
    const scope = this.boardPath(projectIdentifier);
    return this
      .createGrid(type, name, scope, actionAttribute)
      .pipe(
        map((grid) => new Board(grid)),
      );
  }

  /**
   * Retrieve the board path identifier for looking up grids.
   *
   * @param projectIdentifier The current project identifier
   */
  public boardPath(projectIdentifier:string) {
    return this.PathHelper.boardsPath(projectIdentifier);
  }

  protected createCache():StateCacheService<Board> {
    const state = this.states.forType<Board>('boards');
    return new StateCacheService<Board>(state);
  }

  private createGrid(type:BoardType, name:string, scope:string, actionAttribute?:string):Observable<GridResource> {
    const payload:any = _.set({ name }, '_links.scope.href', scope);
    payload.options = {
      type,
    };

    if (actionAttribute) {
      payload.options.attribute = actionAttribute;
    }

    return this
      .apiRoot
      .grids
      .form
      .post(payload)
      .pipe(
        switchMap((form) => this
          .apiRoot
          .grids
          .post(form.payload.$source)),
      );
  }
}
