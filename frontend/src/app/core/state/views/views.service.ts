import { Injectable, inject } from '@angular/core';
import { EffectHandler } from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { ViewsStore } from 'core-app/core/state/views/views.store';
import { IView } from 'core-app/core/state/views/view.model';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';

@Injectable()
@EffectHandler
export class ViewsResourceService extends ResourceStoreService<IView> {
  readonly actions$ = inject(ActionsService);

  protected createStore():ResourceStore<IView> {
    return new ViewsStore();
  }

  protected basePath():string {
    return this.apiV3Service.views.path;
  }
}
