import { Injectable } from '@angular/core';
import {
  catchError,
  tap,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import {
  applyTransaction,
  ID,
} from '@datorama/akita';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { HttpClient } from '@angular/common/http';
import {
  collectionKey,
  insertCollectionIntoState,
} from 'core-app/core/state/collection-store';
import {
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { ViewsStore } from 'core-app/core/state/views/views.store';
import { ViewsQuery } from 'core-app/core/state/views/views.query';
import { IView } from 'core-app/core/state/views/view.model';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { addParamToHref } from 'core-app/shared/helpers/url-helpers';
import {
  CollectionStore,
  ResourceCollectionService,
} from 'core-app/core/state/resource-collection.service';

@EffectHandler
@Injectable()
export class ViewsResourceService extends ResourceCollectionService<IView> {
  private get viewsPath():string {
    return this
      .apiV3Service
      .views
      .path;
  }

  constructor(
    readonly actions$:ActionsService,
    private http:HttpClient,
    private apiV3Service:ApiV3Service,
    private toastService:ToastService,
  ) {
    super();
  }

  fetchViews(params:ApiV3ListParameters):Observable<IHALCollection<IView>> {
    const collectionURL = collectionKey(params);

    return this
      .http
      .get<IHALCollection<IView>>(addParamToHref(this.viewsPath + collectionURL, { pageSize: '-1' }))
      .pipe(
        tap((collection) => insertCollectionIntoState(this.store, collection, collectionURL)),
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      );
  }

  protected createStore():CollectionStore<IView> {
    return new ViewsStore();
  }
}
