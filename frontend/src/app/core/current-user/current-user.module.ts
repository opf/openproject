import {
  Injector,
  NgModule,
} from '@angular/core';

import { CurrentUserService } from './current-user.service';
import { CurrentUserStore } from './current-user.store';
import { CurrentUserQuery } from './current-user.query';
import { ErrorReporterBase } from 'core-app/core/errors/error-reporter-base';
import { take } from 'rxjs/operators';

export function bootstrapModule(injector:Injector):void {
  const currentUserService = injector.get(CurrentUserService);

  (window.ErrorReporter as ErrorReporterBase)
    .addHook(
      () => currentUserService
        .user$
        .pipe(
          take(1),
        )
        .toPromise()
        .then(({ id }) => ({ user: id || 'anon' })),
    );

  const userMeta = document.querySelectorAll('meta[name=current_user]')[0] as HTMLElement|undefined;
  currentUserService.setUser({
    id: userMeta?.dataset.id || null,
    name: userMeta?.dataset.name || null,
    mail: userMeta?.dataset.mail || null,
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
