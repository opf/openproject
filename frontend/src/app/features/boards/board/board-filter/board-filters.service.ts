import { input } from '@openproject/reactivestates';
import { Injectable } from '@angular/core';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

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
