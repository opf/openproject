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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Observable, Subject } from 'rxjs';
import { filter } from 'rxjs/operators';
import { Injectable } from '@angular/core';

export interface BoardSelection {
  /** The query that the selection happened in */
  withinQuery:string;

  /** The focused selected work package */
  focusedWorkPackage:string|null;

  /** Array of selected work packages */
  allSelected:string[];
}

/**
 * Responsible for keeping selected items across all lists of a board,
 * selections in one list will propagate to other lists as well.
 */
@Injectable()
export class BoardListCrossSelectionService {
  private selections$ = new Subject<BoardSelection>();

  /**
   * Marks the selection of one or multiple cards within a list
   * by a user.
   *
   * The primary selected should be open in split screen (if open).
   *
   */
  updateSelection(selection:BoardSelection) {
    this.selections$.next(selection);
  }

  /**
   * Returns an observable for a given query that fires
   * when its selection should be updated.
   *
   * @param id
   */
  selectionsForQuery(id:string):Observable<BoardSelection> {
    return this
      .selections$
      .pipe(
        filter((selection) => selection.withinQuery !== id),
      );
  }

  selections():Observable<BoardSelection> {
    return this.selections$;
  }
}
