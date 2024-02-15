import { Injector, NgModule } from '@angular/core';

import { CurrentUserService } from './current-user.service';
import { CurrentUserStore } from './current-user.store';
import { CurrentUserQuery } from './current-user.query';
import { ErrorReporterBase } from 'core-app/core/errors/error-reporter-base';
import { firstValueFrom } from 'rxjs';

export function bootstrapModule(injector:Injector):void {
  const currentUserService = injector.get(CurrentUserService);

  (window.ErrorReporter as ErrorReporterBase)
    .addHook(
      () => firstValueFrom(currentUserService.user$)
        .then(({ id }) => ({ user: id || 'anon' })),
    );

  const userMeta = document.querySelectorAll('meta[name=current_user]')[0] as HTMLElement|undefined;
  currentUserService.setUser({
    id: userMeta?.dataset.id || null,
    name: userMeta?.dataset.name || null,
    loggedIn: userMeta?.dataset.loggedIn === 'true',
  });
}

@NgModule({
  providers: [
    CurrentUserService,
    CurrentUserStore,
    CurrentUserQuery,
  ],
})
export class CurrentUserModule {
  constructor(injector:Injector) {
    bootstrapModule(injector);
  }
}
