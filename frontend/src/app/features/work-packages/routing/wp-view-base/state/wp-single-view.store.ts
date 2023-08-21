import { Store, StoreConfig } from '@datorama/akita';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';

export interface WpSingleViewState {
  notifications:{
    filters:ApiV3ListFilter[];
  }
}

export function createInitialState():WpSingleViewState {
  return {
    notifications: {
      filters: [],
    },
  };
}

@StoreConfig({ name: 'wp-single-view' })
export class WpSingleViewStore extends Store<WpSingleViewState> {
  constructor() {
    super(createInitialState());
  }
}
