import {EventEmitter} from '@angular/core';
import {Observable} from 'rxjs/Observable';
import {debounceTime, takeUntil} from 'rxjs/operators';
import {Subject} from 'rxjs/Subject';

export class DebouncedEventEmitter<T> {

  private emitter = new EventEmitter<T>();
  private debouncer:Subject<T>;

  constructor(takeUntil$:Observable<true>, debounceTimeInMs:number = 250) {
    this.debouncer = new Subject<T>();
    this.debouncer
      .pipe(
        debounceTime(debounceTimeInMs),
        takeUntil(takeUntil$)
      )
      .subscribe((val) => this.emitter.emit(val));
  }

  public emit(value?:T):void {
    this.debouncer.next(value);
  }

  public subscribe(generatorOrNext?:any, error?:any, complete?:any):any {
    return this.emitter.subscribe(generatorOrNext, error, complete);
  }
}
