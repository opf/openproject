import { Injectable } from '@angular/core';

import {
  NotificationSettingsState, NotificationSettingsStore,
} from './notification-settings.store';
import { Query, QueryEntity } from "@datorama/akita";

@Injectable()
export class NotificationSettingsQuery extends Query<NotificationSettingsState> {
  constructor(protected store: NotificationSettingsStore) {
    super(store);
  }

  //
  // isLoggedIn$ = this.select(state => !!state.id);
  // user$ = this.select(({ id, name, mail }) => ({ id, name, mail }));
  // capabilities$ = this.select('capabilities').pipe(filterNilValue());
}
