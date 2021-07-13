import { Injector, NgModule } from '@angular/core';

import { CurrentUserService } from './current-user.service';
import { CurrentUserStore } from './current-user.store';
import { CurrentUserQuery } from './current-user.query';

export function bootstrapModule(injector:Injector) {
  const currentUserService = injector.get(CurrentUserService);

  window.ErrorReporter.addContext((scope) => {
    currentUserService.user$.subscribe(({ id, name, mail }) => {
      scope.setUser({
        name,
        mail,
        id: id || undefined, // scope expects undefined instead of null
      });
    });
  });

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
