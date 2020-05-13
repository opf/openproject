import {Observable, Subject} from "rxjs";
import {filter} from "rxjs/operators";

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
        filter(selection => selection.withinQuery !== id)
      );
  }

  selections():Observable<BoardSelection> {
    return this.selections$;
  }
}