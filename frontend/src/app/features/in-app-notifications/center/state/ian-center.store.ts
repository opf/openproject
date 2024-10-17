import { Store, StoreConfig } from '@datorama/akita';
import { CollectionResponse } from 'core-app/core/state/resource-store';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { NOTIFICATIONS_MAX_SIZE } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import {
  INotificationPageQueryParameters,
} from 'core-app/features/in-app-notifications/center/state/ian-center.service';

export type InAppNotificationFacet = 'unread'|'all';

export interface IanCenterState {
  params:{
    page:number;
    pageSize:number;
  };
  activeFacet:InAppNotificationFacet;
  filters:INotificationPageQueryParameters;

  activeCollection:CollectionResponse;

  /** Number of elements not showing after max values loaded */
  notLoaded:number;
}

export const IAN_FACET_FILTERS:Record<InAppNotificationFacet, ApiV3ListFilter[]> = {
  unread: [['readIAN', '=', false]],
  all: [],
};

export function createInitialState():IanCenterState {
  return {
    params: {
      pageSize: NOTIFICATIONS_MAX_SIZE,
      page: 1,
    },
    filters: {},
    activeCollection: { ids: [] },
    activeFacet: 'unread',
    notLoaded: 0,
  };
}

@StoreConfig({ name: 'ian-center' })
export class IanCenterStore extends Store<IanCenterState> {
  constructor() {
    super(createInitialState());
  }
}
