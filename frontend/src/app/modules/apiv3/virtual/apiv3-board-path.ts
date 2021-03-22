//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { Board } from "core-app/modules/boards/board/board";
import { Observable } from "rxjs";
import { map, switchMap, tap } from "rxjs/operators";
import { SchemaResource } from "core-app/modules/hal/resources/schema-resource";
import { CachableAPIV3Resource } from "core-app/modules/apiv3/cache/cachable-apiv3-resource";
import { MultiInputState } from "reactivestates";
import { StateCacheService } from "core-app/modules/apiv3/cache/state-cache.service";
import { Apiv3BoardsPaths } from "core-app/modules/apiv3/virtual/apiv3-boards-paths";

export class APIv3BoardPath extends CachableAPIV3Resource<Board> {

  /**
   * Perform a request to the HalResourceService with the current path
   */
  protected load():Observable<Board> {
    return this
      .apiRoot
      .grids
      .id(this.id)
      .get()
      .pipe(
        map(grid => {
          const newBoard = new Board(grid);

          newBoard.sortWidgets();

          return newBoard;
        })
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
          .apiRoot
          .grids
          .id(board.grid)
          .patch(board.grid, schema)
        ),
        map(grid => {
          board.grid = grid;
          board.sortWidgets();
          return board;
        }),
        this.cacheResponse()
      );
  }

  public delete():Observable<unknown> {
    return this
      .apiRoot
      .grids
      .id(this.id)
      .delete()
      .pipe(
        tap(() => this.cache.clearSome(this.id.toString()))
      );
  }

  private fetchSchema(board:Board):Observable<SchemaResource> {
    return this
      .apiRoot
      .grids
      .id(board.grid)
      .form
      .post({})
      .pipe(
        map(form => form.schema)
      );
  }

  protected createCache():StateCacheService<Board> {
    return (this.parent as Apiv3BoardsPaths).cache;
  }
}
