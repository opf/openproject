import { Store, StoreConfig } from '@datorama/akita';
import { Apiv3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';

export interface IanMenuGroupingData {
  value:string;
  count:number;
  projectHasParent?:boolean;
  _links:{
    valueLink:{
      href:string;
    }[];
  };
}

export interface BaseMenuItemData {
  value:string;
  count:number;
}

export interface IanMenuState {
  notificationsByProject:IanMenuGroupingData[],
  notificationsByReason:IanMenuGroupingData[],
  projectsFilter:Apiv3ListParameters,
}

export const IAN_MENU_PROJECT_FILTERS:Apiv3ListParameters = {
  pageSize: 100,
  groupBy: 'project',
  filters: [['read_ian', '=', false]],
};

export const IAN_MENU_REASON_FILTERS:Apiv3ListParameters = {
  pageSize: 100,
  groupBy: 'reason',
  filters: [['read_ian', '=', false]],
};

export function createInitialState():IanMenuState {
  return {
    notificationsByProject: [],
    notificationsByReason: [],
    projectsFilter: {},
  };
}

@StoreConfig({ name: 'ian-menu' })
export class IanMenuStore extends Store<IanMenuState> {
  constructor() {
    super(createInitialState());
  }
}
