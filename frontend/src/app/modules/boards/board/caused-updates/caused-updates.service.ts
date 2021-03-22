import { Injectable } from "@angular/core";
import { QueryResource } from "core-app/modules/hal/resources/query-resource";

/**
 * The service is intended to store all the updates caused to a query by a user.
 * It is e.g. used to not update the board list when the current user moved a card within a list/query.
  */


@Injectable()
export class CausedUpdatesService {
  /** contains all the updates to the query caused by modifications of the user */
  private causedUpdates:string[] = [];

  public includes(query:QueryResource) {
    return this.causedUpdates.includes(this.cacheValue(query));
  }

  public add(query:QueryResource) {
    if (this.causedUpdates.length > 100) {
      this.causedUpdates.splice(0, 90);
    }

    this.causedUpdates.push(this.cacheValue(query));
  }

  private cacheValue(query:QueryResource) {
    return query.updatedAt + query.$href;
  }
}
