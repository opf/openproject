//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable } from '@angular/core';
import { Observable, Subject } from 'rxjs';
import { buffer, debounceTime, filter } from 'rxjs/operators';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ResourceChangesetCommit } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';

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
        buffer(this.events$.pipe(debounceTime(debounceTimeInMs))),
      );
  }

  public push(resourceReference:HalResource|{ id:string, _type:string }, event:Partial<HalEventTypes>) {
    event.id = resourceReference.id!;
    event.resourceType = resourceReference._type!;

    this._events.next(event as HalEvent);
  }
}
