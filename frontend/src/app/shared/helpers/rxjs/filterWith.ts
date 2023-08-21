import {
  filter,
  map,
  withLatestFrom,
} from 'rxjs/operators';
import { Observable } from 'rxjs';

/**
 * Filter emissions from the source observable
 * using values from another observable.
 *
 * Applies the given filter function and maps to the original observable.
 *
 * @param other$ Other observable to observe values
 * @param filterFn Filter to apply to values of other$
 */
export function filterObservable<T, V>(
  other$:Observable<V>,
  filterFn:(val:V) => boolean,
):(source$:Observable<T>) => Observable<T> {
  return (source$) => source$
    .pipe(
      withLatestFrom(other$),
      filter(([, val]) => filterFn(val)),
      map(([source]) => source),
    );
}
