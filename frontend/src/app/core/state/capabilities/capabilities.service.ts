import { Injectable } from '@angular/core';
import {
  catchError,
  distinctUntilChanged,
  filter,
  map,
  switchMap,
  take,
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
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';

@Injectable()
export class CapabilitiesResourceService extends ResourceCollectionService<ICapability> {
  constructor(
    private http:HttpClient,
    private apiV3Service:ApiV3Service,
    private toastService:ToastService,
    private currentUserService:CurrentUserService,
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
   * Require the available capabilities for the given context
   * Returns a cached set if it was loaded already.
   *
   * @param context Context to load permissions for
   * @private
   */
  public requireContext$(context:string):Observable<ICapability[]> {
    return this
      .userContextFilter$(context)
      .pipe(
        switchMap((params) => this.require$(params)),
      );
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
   * Returns an Observable<boolean> indicating whether the user has the required capabilities in the provided context.
   */
  public hasCapabilities$(action:string|string[], contextId = 'global'):Observable<boolean> {
    const actions = _.castArray(action);
    return this
      .requireContext$(contextId)
      .pipe(
        map((capabilities) => actions.reduce(
          (acc, contextAction) => acc && !!capabilities.find((cap) => cap._links.action.href.endsWith(`/api/v3/actions/${contextAction}`)),
          capabilities.length > 0,
        )),
        distinctUntilChanged(),
      );
  }

  /**
   * Returns an Observable<boolean> indicating whether the user has any of the required capabilities in the provided context.
   */
  public hasAnyCapabilityOf$(actions:string|string[], contextId = 'global'):Observable<boolean> {
    const actionsToFilter = _.castArray(actions);
    return this
      .requireContext$(contextId)
      .pipe(
        map((capabilities) => capabilities.reduce(
          (acc, cap) => acc || !!actionsToFilter.find((action) => cap._links.action.href.endsWith(`/api/v3/actions/${action}`)),
          false,
        )),
        distinctUntilChanged(),
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

  fetchCapabilities(params:ApiV3ListParameters):Observable<IHALCollection<ICapability>> {
    return this
      .fetchCollection(this.http, this.capabilitiesPath, params)
      .pipe(
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      );
  }

  userContextFilter$(...contexts:string[]):Observable<ApiV3ListParameters> {
    return this
      .currentUserService
      .user$
      .pipe(
        filter((user) => !!user.id),
        take(1),
        map((user) => {
          const filters:[string, FilterOperator, string[]][] = [['principal', '=', [user.id as string]]];
          if (contexts.length) {
            filters.push(['context', '=', contexts.map((context) => (context === 'global' ? 'g' : `p${context}`))]);
          }

          return { filters, pageSize: -1 };
        }),
      );
  }

  userActionFilter$(...actions:string[]):Observable<ApiV3ListParameters> {
    return this
      .currentUserService
      .user$
      .pipe(
        filter((user) => !!user.id),
        take(1),
        map((user) => {
          const filters:[string, FilterOperator, string[]][] = [['principal', '=', [user.id as string]]];
          if (actions.length) {
            filters.push(['action', '=', actions]);
          }

          return { filters, pageSize: -1 };
        }),
      );
  }

  protected createStore():CollectionStore<ICapability> {
    return new CapabilitiesStore();
  }
}
