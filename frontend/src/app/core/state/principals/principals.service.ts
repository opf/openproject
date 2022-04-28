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
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { HttpClient } from '@angular/common/http';
import { PrincipalsQuery } from 'core-app/core/state/principals/principals.query';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import {
  collectionKey,
  insertCollectionIntoState,
} from 'core-app/core/state/collection-store';
import {
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { PrincipalsStore } from './principals.store';
import { IPrincipal } from './principal.model';
import { IUser } from 'core-app/core/state/principals/user.model';

@EffectHandler
@Injectable()
export class PrincipalsResourceService {
  protected store = new PrincipalsStore();

  readonly query = new PrincipalsQuery(this.store);

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
  ) { }

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

  update(id:ID, principal:Partial<IPrincipal>):void {
    this.store.update(id, principal);
  }

  modifyCollection(params:ApiV3ListParameters, callback:(collection:ID[]) => ID[]):void {
    const key = collectionKey(params);
    this.store.update(({ collections }) => (
      {
        collections: {
          ...collections,
          [key]: {
            ...collections[key],
            ids: [...callback(collections[key]?.ids || [])],
          },
        },
      }
    ));
  }

  removeFromCollection(params:ApiV3ListParameters, ids:ID[]):void {
    const key = collectionKey(params);
    this.store.update(({ collections }) => (
      {
        collections: {
          ...collections,
          [key]: {
            ...collections[key],
            ids: (collections[key]?.ids || []).filter((id) => !ids.includes(id)),
          },
        },
      }
    ));
  }
}
