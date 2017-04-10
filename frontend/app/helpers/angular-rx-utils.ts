import IScope = angular.IScope;
import {Observable, Observer, Subscriber} from "rxjs";
import {TeardownLogic} from "rxjs/Subscription";

// export class ScopedOperator<T, R> {
//
//   constructor(public readonly scope: IScope) {
//   }
//
//   call(subscriber: Subscriber<R>, source: any): TeardownLogic {
//     const scoped = scopedObservable(this.scope, source);
//     return scoped.subscribe();
//   }
// }

export function runInScopeDigest(scope: IScope, fn: () => void) {
  if (scope.$root.$$phase !== "$apply" && scope.$root.$$phase !== "$digest") {
    scope.$apply(fn);
  } else {
    fn();
  }
}

export function scopedObservable<T>(scope: IScope, observable: Observable<T>): Observable<T> {
  return Observable.create((observer: Observer<T>) => {
    var disposable = observable.subscribe(
      value => {
        runInScopeDigest(scope, () => observer.next(value));
      },
      exception => {
        runInScopeDigest(scope, () => observer.error(exception));
      },
      () => {
        runInScopeDigest(scope, () => observer.complete());
      }
    );

    scope.$on("$destroy", () => {
      return disposable.unsubscribe();
    });
  });
}

export function asyncTest<T>(done: (error?: any) => void, fn: (value: T) => any): (T:any) => any {
  return (value: T) => {
    try {
      fn(value);
      done();
    } catch (err) {
      done(err);
    }
  }

}

export function scopeDestroyed$(scope: IScope): Observable<IScope> {
  return Observable.create((s:Observer<IScope>) => {
    scope.$on("$destroy", () => {
      s.next(scope);
      s.complete();
    });
  });
}
