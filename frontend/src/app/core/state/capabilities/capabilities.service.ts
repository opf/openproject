import { Injectable } from '@angular/core';
import {
  catchError,
  tap,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import {
  collectionKey,
  insertCollectionIntoState,
} from 'core-app/core/state/collection-store';
import { ICapability } from 'core-app/core/state/capabilities/capability.model';
import { CapabilitiesStore } from 'core-app/core/state/capabilities/capabilities.store';
import {
  CollectionStore,
  ResourceCollectionService,
} from 'core-app/core/state/resource-collection.service';

@Injectable()
export class CapabilitiesResourceService extends ResourceCollectionService<ICapability> {
  private get capabilitiesPath():string {
    return this
      .apiV3Service
      .capabilities
      .path;
  }

  constructor(
    private http:HttpClient,
    private apiV3Service:ApiV3Service,
    private toastService:ToastService,
  ) {
    super();
  }

  fetchCapabilities(params:ApiV3ListParameters):Observable<IHALCollection<ICapability>> {
    const collectionURL = collectionKey(params);

    return this
      .http
      .get<IHALCollection<ICapability>>(this.capabilitiesPath + collectionURL)
      .pipe(
        tap((collection) => insertCollectionIntoState(this.store, collection, collectionURL)),
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      );
  }

  protected createStore():CollectionStore<ICapability> {
    return new CapabilitiesStore();
  }
}
