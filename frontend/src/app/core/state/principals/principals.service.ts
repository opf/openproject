import { Injectable, inject } from '@angular/core';
import { EffectHandler } from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { PrincipalsStore } from './principals.store';
import { IPrincipal } from './principal.model';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';

@Injectable()
@EffectHandler
export class PrincipalsResourceService extends ResourceStoreService<IPrincipal> {
  readonly actions$ = inject(ActionsService);

  protected createStore():ResourceStore<IPrincipal> {
    return new PrincipalsStore();
  }

  protected basePath():string {
    return this.apiV3Service.principals.path;
  }
}
