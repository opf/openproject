import { Injectable } from '@angular/core';
import {
  catchError,
  map,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { ICapability } from 'core-app/core/state/capabilities/capability.model';
import { CapabilitiesStore } from 'core-app/core/state/capabilities/capabilities.store';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

@Injectable()
export class CapabilitiesResourceService extends ResourceStoreService<ICapability> {
  @InjectField() toastService:ToastService;

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
      .fetchCollection(params)
      .pipe(
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      );
  }

  protected createStore():ResourceStore<ICapability> {
    return new CapabilitiesStore();
  }

  protected basePath():string {
    return this.apiV3Service.capabilities.path;
  }
}
