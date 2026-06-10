import { multiInput } from '@openproject/reactivestates';
import { BcfExtensionResource } from 'core-app/features/bim/bcf/api/extensions/bcf-extension.resource';
import { BcfApiService } from 'core-app/features/bim/bcf/api/bcf-api.service';
import {
  firstValueFrom,
  Observable,
} from 'rxjs';
import { map } from 'rxjs/operators';
import { Injectable, inject } from '@angular/core';

export type AllowedExtensionKey = keyof BcfExtensionResource;

@Injectable({ providedIn: 'root' })
export class BcfAuthorizationService {
  readonly bcfApi = inject(BcfApiService);

  // Poor mans caching to avoid repeatedly fetching from the backend.
  protected authorizationMap = multiInput<BcfExtensionResource>();

  /**
   * Returns an observable boolean whether the given action
   * is authorized in the project by using the project extensions.
   *
   * Ensures the extension is loaded only once per project
   *
   * @param projectIdentifier Project identifier to check permission in
   * @param extension The extension key to check for
   * @param action The desired action
   */
  public authorized$(projectIdentifier:string, extension:AllowedExtensionKey, action:string):Observable<boolean> {
    const state = this.authorizationMap.get(projectIdentifier);

    state.putFromPromiseIfPristine(() => firstValueFrom(
      this.bcfApi
        .projects.id(projectIdentifier)
        .extensions
        .get(),
    ));

    return state
      .values$()
      .pipe(
        map(
          (resource) => resource[extension] && resource[extension].includes(action),
        ),
      );
  }

  /**
   * One-time check to determine current allowed state.
   *
   * @param projectIdentifier Project identifier to check permission in
   * @param extension The extension key to check for
   * @param action The desired action
   */
  public isAllowedTo(projectIdentifier:string, extension:AllowedExtensionKey, action:string):Promise<boolean> {
    return firstValueFrom(this.authorized$(projectIdentifier, extension, action))
      .catch(() => false);
  }
}
