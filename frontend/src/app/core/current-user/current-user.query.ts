import { Injectable } from '@angular/core';
import { filterNilValue, Query } from '@datorama/akita';
import { Observable, combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import {
  CurrentUserStore,
  CurrentUserState,
  CurrentUser,
} from './current-user.store';
import { CapabilityResource } from "core-app/features/hal/resources/capability-resource";

@Injectable()
export class CurrentUserQuery extends Query<CurrentUserState> {
  constructor(protected store: CurrentUserStore) {
    super(store);
  }

  isLoggedIn$ = this.select(state => !!state.id);
  user$ = this.select(({ id, name, mail }) => ({ id, name, mail }));
  capabilities$ = this.select('capabilities').pipe(filterNilValue());
}
