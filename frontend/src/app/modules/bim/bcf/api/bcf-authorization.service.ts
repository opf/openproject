import {multiInput} from "reactivestates";
import {BcfExtensionResource} from "core-app/modules/bim/bcf/api/extensions/bcf-extension.resource";
import {BcfApiService} from "core-app/modules/bim/bcf/api/bcf-api.service";
import {Observable} from "rxjs";
import {map, take} from "rxjs/operators";
import {Injectable} from "@angular/core";

export type AllowedExtensionKey = keyof BcfExtensionResource;

@Injectable({ providedIn: 'root' })
export class BcfAuthorizationService {

  // Poor mans caching to avoid repeatedly fetching from the backend.
  protected authorizationMap = multiInput<BcfExtensionResource>();

  constructor(readonly bcfApi:BcfApiService) {
  }

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

    state.putFromPromiseIfPristine(() =>
      this.bcfApi
        .projects.id(projectIdentifier)
        .extensions
        .get()
        .toPromise()
    );

    return state
      .values$()
      .pipe(
        map(
          resource => resource[extension] && resource[extension].includes(action)
        )
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
    return this
      .authorized$(projectIdentifier, extension, action)
      .pipe(
        take(1)
      )
      .toPromise()
      .catch(() => false);
  }
}

