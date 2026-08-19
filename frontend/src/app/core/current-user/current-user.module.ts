import { Injector, NgModule, inject } from '@angular/core';

import { CurrentUserService } from './current-user.service';
import { CurrentUserStore } from './current-user.store';
import { CurrentUserQuery } from './current-user.query';
import { firstValueFrom } from 'rxjs';
import { getMetaValue } from '../setup/globals/global-helpers';

function loadUserMetadata(currentUserService:CurrentUserService) {
  currentUserService.setUser({
    id: getMetaValue('current_user', 'id', null),
    name: getMetaValue('current_user', 'name', null),
    loggedIn: getMetaValue('current_user', 'loggedIn') === 'true'
  });
}

export function bootstrapModule(injector:Injector):void {
  const currentUserService = injector.get(CurrentUserService);

  window.ErrorReporter
    .addHook(
      () => firstValueFrom(currentUserService.user$)
        .then(({ id }) => ({ user: id || 'anon' })),
    );

  loadUserMetadata(currentUserService);
  document.addEventListener('turbo:load', () => loadUserMetadata(currentUserService));
}

@NgModule({
  providers: [
    CurrentUserService,
    CurrentUserStore,
    CurrentUserQuery,
  ],
})
export class CurrentUserModule {
  constructor() {
    const injector = inject(Injector);

    bootstrapModule(injector);
  }
}
