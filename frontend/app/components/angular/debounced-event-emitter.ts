import {Subject} from 'rxjs';
import {Observable} from 'rxjs/Observable';
import {EventEmitter} from '@angular/core';

export class DebouncedEventEmitter<T> {
  private emitter = new EventEmitter<T>();
  private debouncer:Subject<T>;

  constructor(takeUntil:Observable<true>, debounceTimeInMs:number = 250) {
    this.debouncer = new Subject<T>();
    this.debouncer
      .debounceTime(debounceTimeInMs)
      .takeUntil(takeUntil)
      .subscribe((val) => this.emitter.emit(val));
  }

  public emit(value?:T):void {
    this.debouncer.next(value);
  }

  public subscribe(generatorOrNext?:any, error?:any, complete?:any):any {
    return this.emitter.subscribe(generatorOrNext, error, complete);
  }
}
