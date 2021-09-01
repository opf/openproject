import { Query } from '@datorama/akita';
import {
  IanBellState,
  IanBellStore,
} from 'core-app/features/in-app-notifications/bell/state/ian-bell.store';

export class IanBellQuery extends Query<IanBellState> {
  constructor(protected store:IanBellStore) {
    super(store);
  }
}