import { Injectable, inject } from '@angular/core';
import { Query } from '@datorama/akita';
import { CurrentUserState, CurrentUserStore } from './current-user.store';

@Injectable()
export class CurrentUserQuery extends Query<CurrentUserState> {
  protected store:CurrentUserStore;

  constructor() {
    const store = inject(CurrentUserStore);

    super(store);

    this.store = store;
  }

  isLoggedIn$ = this.select((state) => !!state.loggedIn);

  user$ = this.select((user) => user);
}
