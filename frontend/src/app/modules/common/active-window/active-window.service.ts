import { Inject, Injectable } from "@angular/core";
import { DOCUMENT } from "@angular/common";
import { BehaviorSubject, Observable, Subject } from "rxjs";
import { debugLog } from "core-app/helpers/debug_output";

@Injectable({ providedIn: 'root' })
export class ActiveWindowService {

  private activeState$ = new BehaviorSubject<boolean>(true);

  constructor(@Inject(DOCUMENT) document:Document) {
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState) {
        debugLog("Browser window has visibility state changed to " + document.visibilityState);
        this.activeState$.next(document.visibilityState === 'visible');
      }
    });
  }

  /**
   * Returns whether the browser window/tab is active
   */
  public get isActive():boolean {
    return this.activeState$.value;
  }

  /**
   * Observable for notifying when visibility changes
   */
  public get active$():Observable<boolean> {
    return this.activeState$.asObservable();
  }
}