import { pairwise, filter, map } from 'rxjs/operators';
import { Query } from '@datorama/akita';
import {
  IanBellState,
  IanBellStore,
} from 'core-app/features/in-app-notifications/bell/state/ian-bell.store';

export class IanBellQuery extends Query<IanBellState> {
  unread$ = this.select('totalUnread');

  unreadCountChanged$ = this.unread$.pipe(
    pairwise(),
    filter(([last, curr]) => curr !== last),
    map(([, curr]) => curr),
  );

  unreadCountIncreased$ = this.unread$.pipe(
    pairwise(),
    filter(([last, curr]) => curr > last),
    map(([, curr]) => curr),
  );

  constructor(protected store:IanBellStore) {
    super(store);
  }
}
