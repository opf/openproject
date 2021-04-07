import { APP_INITIALIZER, Injector, NgModule } from "@angular/core";
import { CurrentUserService } from "./current-user.service";

export function bootstrapModule(injector:Injector) {
  const currentUser = injector.get(CurrentUserService);

  window.ErrorReporter.addContext((scope) => {
    if (currentUser.isLoggedIn) {
      scope.setUser({ name: currentUser.name, id: currentUser.userId, email: currentUser.mail });
    }
  });
}

@NgModule({
  providers: [
    CurrentUserService,
  ],
})
export class CurrentUserModule {
  constructor(injector:Injector) {
    bootstrapModule(injector);
  }
}
