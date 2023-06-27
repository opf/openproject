import { Injectable, Injector } from '@angular/core';
import { map } from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { Observable } from 'rxjs';


@Injectable()
export class TimeEntryService {
  constructor(
    readonly injector:Injector,
    readonly apiV3Service:ApiV3Service,) {
  }

  public getActiveTimeEntry():Observable<TimeEntryResource | null> {
    const filters = new ApiV3FilterBuilder();
    filters.add('ongoing', '=', true);
    
    return this
      .apiV3Service
      .time_entries
      .filtered(filters)
      .get().pipe(
        map((collection) => collection.elements.pop() || null),
      );
  }

}
