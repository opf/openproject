import { Injectable } from '@angular/core';
import { filterNilValue, Query } from '@datorama/akita';
import { Observable } from 'rxjs';
import { CapabilityResource } from 'core-app/features/hal/resources/capability-resource';
import { CurrentUserState, CurrentUserStore } from './current-user.store';

@Injectable()
export class CurrentUserQuery extends Query<CurrentUserState> {
  constructor(protected store:CurrentUserStore) {
    super(store);
  }

  isLoggedIn$ = this.select((state) => !!state.id);

  user$ = this.select(({ id, name, mail }) => ({ id, name, mail }));

  capabilities$ = this.select('capabilities').pipe(filterNilValue()) as Observable<CapabilityResource[]>;
}
