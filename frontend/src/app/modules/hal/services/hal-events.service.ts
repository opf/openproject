import { Injectable } from "@angular/core";
import { Observable, Subject } from "rxjs";
import { buffer, debounceTime, filter } from "rxjs/operators";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { ResourceChangesetCommit } from "core-app/modules/fields/edit/services/hal-resource-editing.service";

export interface HalEvent {
  id:string;
  eventType:string;
  resourceType:string;
  commit?:ResourceChangesetCommit;
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
        buffer(this.events$.pipe(debounceTime(debounceTimeInMs)))
      );
  }

  public push(resourceReference:HalResource|{ id:string, _type:string }, event:Partial<HalEventTypes>) {
    event.id = resourceReference.id!;
    event.resourceType = resourceReference._type!;

    this._events.next(event as HalEvent);
  }
}
