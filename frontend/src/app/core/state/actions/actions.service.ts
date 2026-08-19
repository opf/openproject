import { Injectable } from '@angular/core';
import { Observable, Subject } from 'rxjs';
import { ActionCreator } from 'ts-action/action';
import { ActionType } from 'ts-action';
import { ofType } from 'ts-action-operators';
import { debugLog } from 'core-app/shared/helpers/debug_output';

export interface Action {
  type:string;

  [key:string]:unknown;
}

@Injectable({ providedIn: 'root' })
export class ActionsService {
  private actions = new Subject<Action>();

  /** Entire event stream */
  public actions$ = this.actions.asObservable();

  /**
   * Observe one or more event type
   * @param action The set of action creators to listen for
   * */
  ofType<C extends ActionCreator>(action:C):Observable<ActionType<C>> {
    return this
      .actions$
      .pipe(
        ofType(action),
      );
  }

  dispatch(action:Action):void {
    debugLog('Dispatching action: %O', action.type);
    this.actions.next(action);
  }
}
