import { Injectable } from '@angular/core';
import { Query } from '@datorama/akita';
import { CurrentUserState, CurrentUserStore } from './current-user.store';

@Injectable()
export class CurrentUserQuery extends Query<CurrentUserState> {
  constructor(protected store:CurrentUserStore) {
    super(store);
  }

  isLoggedIn$ = this.select((state) => !!state.loggedIn);

  user$ = this.select((user) => user);
}
