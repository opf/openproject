import { Injectable } from '@angular/core';
import {
  catchError,
  map,
  switchMap,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { collectionKey } from 'core-app/core/state/collection-store';
import { ICapability } from 'core-app/core/state/capabilities/capability.model';
import { CapabilitiesStore } from 'core-app/core/state/capabilities/capabilities.store';
import {
  CollectionStore,
  ResourceCollectionService,
} from 'core-app/core/state/resource-collection.service';

@Injectable()
export class CapabilitiesResourceService extends ResourceCollectionService<ICapability> {
  constructor(
    private http:HttpClient,
    private apiV3Service:ApiV3Service,
    private toastService:ToastService,
  ) {
    super();
  }

  private get capabilitiesPath():string {
    return this
      .apiV3Service
      .capabilities
      .path;
  }

  /**
   * Require the available capabilities for the given filter params
   * Returns a cached set if it was loaded already.
   *
   * @param params List params to require
   * @private
   */
  public require$(params:ApiV3ListParameters):Observable<ICapability[]> {
    const key = collectionKey(params);
    if (this.collectionExists(key) || this.collectionLoading(key)) {
      return this.loadedCollection(key);
    }

    return this
      .fetchCapabilities(params)
      .pipe(
        switchMap(() => this.loadedCollection(key)),
      );
  }

  /**
   * Returns the loaded capabilities for a context
   */
  public loadedCapabilities$(contextId:string):Observable<ICapability[]> {
    return this
      .query
      .selectAll()
      .pipe(
        map((capabilities) => capabilities.filter((cap) => cap._links.context.href.endsWith(`/${contextId}`))),
      );
  }

  public fetchCapabilities(params:ApiV3ListParameters):Observable<IHALCollection<ICapability>> {
    return this
      .fetchCollection(this.http, this.capabilitiesPath, params)
      .pipe(
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
