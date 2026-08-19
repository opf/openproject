import {
  EntityStore,
  StoreConfig,
} from '@datorama/akita';
import {
  ResourceState,
  createInitialResourceState,
} from 'core-app/core/state/resource-store';
import { IDay } from 'core-app/core/state/days/day.model';

export interface DayState extends ResourceState<IDay> {
}

@StoreConfig({ name: 'days' })
export class DayStore extends EntityStore<DayState> {
  constructor() {
    super(createInitialResourceState());
  }
}
