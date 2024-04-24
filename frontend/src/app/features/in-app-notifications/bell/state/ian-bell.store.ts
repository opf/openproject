import {
  Store,
  StoreConfig,
} from '@datorama/akita';

export interface IanBellState {
  totalUnread:number;
}

export function createInitialState():IanBellState {
  return {
    totalUnread: 0,
  };
}

@StoreConfig({ name: 'ian-bell' })
export class IanBellStore extends Store<IanBellState> {
  constructor() {
    super(createInitialState());
  }
}
