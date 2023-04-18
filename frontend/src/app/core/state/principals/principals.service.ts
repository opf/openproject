import { Injectable } from '@angular/core';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { EffectHandler } from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { PrincipalsStore } from './principals.store';
import { IPrincipal } from './principal.model';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

@EffectHandler
@Injectable()
export class PrincipalsResourceService extends ResourceStoreService<IPrincipal> {
  @InjectField() actions$:ActionsService;

  @InjectField() toastService:ToastService;

  protected createStore():ResourceStore<IPrincipal> {
    return new PrincipalsStore();
  }

  protected basePath():string {
    return this.apiV3Service.principals.path;
  }
}
