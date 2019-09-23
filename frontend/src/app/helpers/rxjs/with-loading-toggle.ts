import {Observable} from "rxjs";
import {tap} from "rxjs/operators";

/**
 * Manipulate a loading flag on the given component while loading
 *
 * @param component
 * @param attribute The attribute to toggle
 */
export function withLoadingToggle<T>(component:any, attribute:string):(source:Observable<T>) => Observable<T> {
  return (source$:Observable<T>) => {
    component[attribute] = true;

    return source$.pipe(
      tap(
        () => component[attribute] = false,
        () => component[attribute] = false,
        () => component[attribute] = false
      )
    );
  };
}
