import {
  EntityStore,
  StoreConfig,
} from '@datorama/akita';
import {
  ResourceState,
  createInitialResourceState,
} from 'core-app/core/state/resource-store';
import { IWeekday } from 'core-app/core/state/days/weekday.model';

export interface WeekdayState extends ResourceState<IWeekday> {
}

@StoreConfig({ name: 'weekdays' })
export class WeekdayStore extends EntityStore<WeekdayState> {
  constructor() {
    super(createInitialResourceState());
  }
}
