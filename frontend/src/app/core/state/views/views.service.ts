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
import { collectionKey } from 'core-app/core/state/collection-store';
import {
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { ViewsStore } from 'core-app/core/state/views/views.store';
import { ViewsQuery } from 'core-app/core/state/views/views.query';
import { IView } from 'core-app/core/state/views/view.model';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';

@EffectHandler
@Injectable()
export class ViewsResourceService {
  protected store = new ViewsStore();

  readonly query = new ViewsQuery(this.store);

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
  }

  fetchViews(params:ApiV3ListParameters):Observable<IHALCollection<IView>> {
    const collectionURL = collectionKey(params);

    return this
      .http
      .get<IHALCollection<IView>>(this.viewsPath + collectionURL)
      .pipe(
        tap((events) => {
          applyTransaction(() => {
            this.store.add(events._embedded.elements);
            this.store.update(({ collections }) => (
              {
                collections: {
                  ...collections,
                  [collectionURL]: {
                    ...collections[collectionURL],
                    ids: events._embedded.elements.map((el) => el.id),
                  },
                },
              }
            ));
          });
        }),
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      );
  }

  update(id:ID, view:Partial<IView>):void {
    this.store.update(id, view);
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
