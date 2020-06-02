import {Injectable} from "@angular/core";
import {Observable, Subject} from "rxjs";
import {buffer, debounceTime, filter, scan} from "rxjs/operators";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

export interface HalEvent {
  id:string;
  eventType:string;
  resourceType:string;
}

export interface HalCreatedEvent extends HalEvent {
  eventType:'created';
}

export interface HalUpdatedEvent extends HalEvent {
  eventType:'updated';
}

export interface RelatedWorkPackageEvent extends HalEvent {
  eventType:'association';
  relatedWorkPackage:string|null;
  relationType:string;
}

export interface HalDeletedEvent extends HalEvent {
  eventType:'deleted';
}

export type HalEventTypes =
  HalCreatedEvent|HalUpdatedEvent|RelatedWorkPackageEvent|HalDeletedEvent;

@Injectable({ providedIn: 'root' })
export class HalEventsService {
  private _events = new Subject<HalEvent>();

  /** Entire event stream */
  public events$ = this._events.asObservable();

  /** Aggregated events */
  public aggregated$(resourceType:string, debounceTimeInMs = 500):Observable<HalEvent[]> {
    return this
      .events$
      .pipe(
        filter((event:HalEvent) => event.resourceType === resourceType),
        buffer(this.events$.pipe(debounceTime(debounceTimeInMs))),
        scan((acc, curr) => acc.concat(curr))
      );
  }

  public push(resourceReference:HalResource|{id:string, _type:string}, event:Partial<HalEventTypes>) {
    event.id = resourceReference.id!;
    event.resourceType = resourceReference._type!;

    this._events.next(event as HalEvent);
  }
}
