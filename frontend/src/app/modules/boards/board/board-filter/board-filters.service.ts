import { ApiV3Filter } from "core-components/api/api-v3/api-v3-filter-builder";
import { input } from "reactivestates";
import { Injectable } from "@angular/core";

@Injectable()
export class BoardFiltersService {
  /**
   * We need to remember the current filter, that may either come
   * from the saved board, or were assigned by the user.
   *
   * This is due to the fact we do not work on an query object here.
   */
  filters = input<ApiV3Filter[]>([]);

  get current():ApiV3Filter[] {
    return this.filters.getValueOr([]);
  }
}