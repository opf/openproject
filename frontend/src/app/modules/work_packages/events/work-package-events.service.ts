import {Injectable} from "@angular/core";
import {Observable, Subject} from "rxjs";
import {buffer, debounceTime, scan} from "rxjs/operators";

export interface WorkPackageEvent {
  id:string;
  type:string;
}

export interface WorkPackageCreatedEvent extends WorkPackageEvent {
  type:'created';
}

export interface WorkPackageUpdatedEvent extends WorkPackageEvent {
  type:'updated';
}

export interface RelatedWorkPackageEvent extends WorkPackageEvent {
  type:'association';
  relatedWorkPackage:string|null;
  relationType:string;
}

export interface WorkPackageDeletedEvent extends WorkPackageEvent {
  type:'deleted';
}

export type WorkPackageEventTypes =
  WorkPackageCreatedEvent|WorkPackageUpdatedEvent|RelatedWorkPackageEvent|WorkPackageDeletedEvent;

@Injectable()
export class WorkPackageEventsService {
  private _events = new Subject<WorkPackageEvent>();

  /** Entire event stream */
  public events$ = this._events.asObservable();

  /** Aggregated events */
  public aggregated$(debounceTimeInMs = 500):Observable<WorkPackageEvent[]> {
    return this
      .events$
      .pipe(
        buffer(this.events$.pipe(debounceTime(debounceTimeInMs))),
        scan((acc, curr) => acc.concat(curr))
      );
  }

  public push(event:WorkPackageEventTypes) {
    this._events.next(event);
  }
}
