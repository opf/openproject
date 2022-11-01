import { Injectable } from '@angular/core';
import {
  catchError,
  tap,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import { applyTransaction } from '@datorama/akita';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { HttpClient } from '@angular/common/http';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import {
  collectionKey,
  insertCollectionIntoState,
} from 'core-app/core/state/collection-store';
import { EffectHandler } from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { PrincipalsStore } from './principals.store';
import { IPrincipal } from './principal.model';
import { IUser } from 'core-app/core/state/principals/user.model';
import {
  CollectionStore,
  ResourceCollectionService,
} from 'core-app/core/state/resource-collection.service';

@EffectHandler
@Injectable()
export class PrincipalsResourceService extends ResourceCollectionService<IPrincipal> {
  private get principalsPath():string {
    return this
      .apiV3Service
      .principals
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

  fetchUser(id:string|number):Observable<IUser> {
    return this.http
      .get<IUser>(this.apiV3Service.users.id(id).path)
      .pipe(
        tap((data) => {
          applyTransaction(() => {
            this.store.upsertMany([data]);
          });
        }),
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      );
  }

  fetchPrincipals(params:ApiV3ListParameters):Observable<IHALCollection<IPrincipal>> {
    const collectionURL = collectionKey(params);

    return this
      .http
      .get<IHALCollection<IPrincipal>>(this.principalsPath + collectionURL)
      .pipe(
        tap((collection) => insertCollectionIntoState(this.store, collection, collectionURL)),
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      );
  }

  protected createStore():CollectionStore<IPrincipal> {
    return new PrincipalsStore();
  }
}
