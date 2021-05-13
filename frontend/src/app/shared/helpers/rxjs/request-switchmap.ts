import { Observable, Subject } from "rxjs";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { switchMap, takeUntil } from "rxjs/operators";

export type RequestSwitchmapHandler<T, R> = (input:T) => Observable<R>;

export class RequestSwitchmap<T, R = HalResource> {

  /** Input request state */
  private requests = new Subject<T>();

  /** Output switchmap observable */
  private responses$ = this.requests
    .pipe(
      // Stream the request, switchMap will result in previous requests to be cancelled
      switchMap(this.handler)
    );

  /**
   *
   * @param handler switch map handler function to output a response observable
   */
  constructor(readonly handler:RequestSwitchmapHandler<T, R>) {
  }

  /**
   * Append a new request for the given request value and pass
   * that to the switchmap handler
   * @param newValue
   */
  public request(newValue:T) {
    this.requests.next(newValue);
  }

  /**
   * Observe the switched response
   */
  public observe(until:Observable<unknown>) {
    return this
      .responses$
      .pipe(
        takeUntil(until)
      );
  }
}
