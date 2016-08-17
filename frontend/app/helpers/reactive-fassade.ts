import {scopedObservable, runInScopeDigest} from "./utils/angular-rx-utils";
import Observable = Rx.Observable;
import IScope = angular.IScope;
import IPromise = Rx.IPromise;

let logFn: (msg: string) => any = null;

export function setStateLogFunction(fn: (msg: string) => any) {
  logFn = fn;
}

export abstract class StoreElement {

  public pathInStore: string = null;

  log(msg: string) {
    if (this.pathInStore === null || logFn === null) {
      return;
    }

    logFn("[" + this.pathInStore + "] " + msg);
  }
}


type LoaderFn = () => IPromise<any>;

export class LoadingState<T> extends StoreElement {

  private counter = 0;

  private subject = new Rx.ReplaySubject<[number, T]>(1);

  private observable: Observable<[number, T]>;

  private lastLoadRequestedTimestamp: number = 0;

  public minimumTimeoutInMs: number;

  private loaderFn: LoaderFn = (): any => {
    throw "loaderFn not defined";
  };

  constructor(minimumTimeoutInMs: number = 5000) {
    super();
    this.minimumTimeoutInMs = minimumTimeoutInMs;
    this.observable = this.subject
      .filter(val => val[1] !== null);
  }

  public clear() {
    this.log("clear");
    this.lastLoadRequestedTimestamp = 0;
    this.setState(this.counter++, null);
  }

  public setLoaderFn(loaderFn: LoaderFn) {
    this.log("setLoaderFn");
    this.loaderFn = loaderFn;
  }

  // Force

  public forceLoadAndGet(scope: IScope): IPromise<T> {
    const currentCounter = this.counter++;
    this.lastLoadRequestedTimestamp = Date.now();

    this.log("loader called");
    return this.loaderFn().then(val => {
      runInScopeDigest(scope, () => {
        this.setState(currentCounter, val);
      });
      return val;
    });
  }

  public forceLoadAndObserve(scope: IScope): Observable<T> {
    const currentCounter = this.counter;
    this.forceLoadAndGet(null);
    return this.scopedObservable(scope)
      .skipWhile((val) => {
        return val[0] < currentCounter;
      })
      .map(val => val[1]);
  }

  // Maybe

  public maybeLoadAndGet(scope: IScope): IPromise<T> {
    if (this.isTimeoutPassed()) {
      return this.forceLoadAndGet(scope);
    } else {
      return this.get();
    }
  }

  public maybeLoadAndObserve(scope: IScope): Observable<T> {
    this.maybeLoadAndGet(null);
    return this.observe(scope);
  }

  // Passive

  public get(): IPromise<T> {
    return this.observable.take(1).map(val => val[1]).toPromise();
  }

  public observe(scope: IScope): Observable<T> {
    return this.scopedObservable(scope).map(val => val[1]);
  }

  // --------------------------------------------------------------

  private setState(counter: number, val: T) {
    this.subject.onNext([counter, val]);
  }

  private isTimeoutPassed(): boolean {
    return (Date.now() - this.lastLoadRequestedTimestamp) > this.minimumTimeoutInMs;
  }

  private scopedObservable(scope: IScope): Observable<[number, T]> {
    return scope ? scopedObservable(scope, this.observable) : this.observable;
  }
}

interface PromiseLike<T> {
  then(callback: (value: T) => any): any;
}

export class State<T> extends StoreElement {

  private subject = new Rx.ReplaySubject<T>(1);

  private observable: Observable<T>;

  constructor() {
    super();
    this.observable = this.subject
      .filter(val => val !== null);
  }

  public clear() {
    this.setState(null);
  }

  public put(value: T) {
    this.log("put");
    this.setState(value);
  }

  public putFromPromise(promise: PromiseLike<T>) {
    this.log("putFromPromise");
    this.clear();
    promise.then((value: T) => {
      this.setState(value);
    });
  }

  public get(): IPromise<T> {
    return this.observable.take(1).toPromise();
  }

  public observe(scope: IScope): Observable<T> {
    return this.scopedObservable(scope);
  }

  private setState(val: T) {
    this.subject.onNext(val);
  }

  private scopedObservable(scope: IScope): Observable<T> {
    return scope ? scopedObservable(scope, this.observable) : this.observable;
  }

}

interface NumberMap<T> {
  [id: number]: T;
}
export class MultiState<T> extends StoreElement {

  private subject = new Rx.BehaviorSubject<NumberMap<T>>({});

  private observable: Observable<NumberMap<T>>;

  constructor() {
    super();
    this.observable = this.subject;
    // .filter(val => val !== null);
  }

  public clear() {
    this.setState({});
  }

  public put(id: number, value: T) {
    this.log("put");

    this.observable.take(1).subscribe(map => {
      const copy: any = _.assign({}, map);
      copy[id] = value;
      this.setState(copy);
    });
  }

  public get(id: number): IPromise<T> {
    return this.observable
      .map(val => val[id])
      .filter(val => val !== undefined)
      .take(1)
      .toPromise();
  }

  // public observe(scope: IScope): Observable<T> {
  //     return this.scopedObservable(scope);
  // }

  private setState(map: NumberMap<T>) {
    this.subject.onNext(map);
  }

  // private scopedObservable(scope: IScope): Observable<T> {
  //     return scope ? scopedObservable(scope, this.observable) : this.observable;
  // }

}

function traverse(elem: any, path: string) {
  const values = _.toPairs(elem);
  for (let [key, value] of values) {
    let location = path.length > 0 ? path + "." + key : key;
    if (value instanceof StoreElement) {
      value.pathInStore = location;
    } else {
      traverse(value, location);
    }
  }
}

export function initStates(states: any) {
  return traverse(states, "");
}


/////////////////////////////////////////////////////////////////

// States
// const states = {
//     a1: new State<number>(),
//     complex: {
//         b1: new State<string>(),
//         b2: new State<string>(),
//         b3: new MultiState<string>()
//     }
// };
// initStates(states);
// setStateLogFunction(log => console.trace(log));

// Subscriber
// states.complex.b2.observe(null).subscribe(val => {
//     console.log("1:" + val);
// });

// states.complex.b3.get(1).then(val => {
//     console.log("2:" + val);
// });


// in Actions
// states.complex.b2.put("a");

/////////////////////////////////////////////////////////////////



// const ms = new MultiState<string>();
// ms.get(1).then(val => {
//     console.log("a:" + val);
// });
//
// ms.get(2).then(val => {
//     console.log("b:" + val);
// });

// ms.put(1, "aaa");
// ms.put(3, "ccc");

