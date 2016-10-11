import Observer = Rx.Observer;
import Observable = Rx.Observable;
import IScope = angular.IScope;

export function runInScopeDigest(scope: IScope, fn: () => void) {
  if (scope.$root.$$phase !== "$apply" && scope.$root.$$phase !== "$digest") {
    scope.$apply(fn);
  } else {
    fn();
  }
}

export function scopedObservable<T>(scope: IScope, observable: Observable<T>): Observable<T> {
  return Rx.Observable.create((observer: Observer<T>) => {
    var disposable = observable.subscribe(
      value => {
        runInScopeDigest(scope, () => observer.onNext(value));
      },
      exception => {
        runInScopeDigest(scope, () => observer.onError(exception));
      },
      () => {
        runInScopeDigest(scope, () => observer.onCompleted());
      }
    );

    scope.$on("$destroy", () => {
      return disposable.dispose();
    });
  });
}

export function asyncTest<T>(done: (error?: any) => void, fn: (value: T) => any): (T) => any {
  return (value: T) => {
    try {
      fn(value);
      done();
    } catch (err) {
      done(err);
    }
  }

}
