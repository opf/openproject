import { AbstractControl } from '@angular/forms';
import {
  Observable,
  of,
} from 'rxjs';
import {
  catchError,
  map,
  take,
} from 'rxjs/operators';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { CapabilitiesResourceService } from 'core-app/core/state/capabilities/capabilities.service';

export const ProjectAllowedValidator = (capabilitiesService:CapabilitiesResourceService) => (control:AbstractControl):Observable<null|{ lackingPermission:boolean }> => {
  const href = control.value?.href || control.value?.$links?.self.href;
  const id = href ? idFromLink(href) : control.value;
  return capabilitiesService
    .hasCapabilities$(
      'memberships/create',
      id,
    )
    .pipe(
      take(1),
      map((isAllowed) => (isAllowed ? null : { lackingPermission: true })),
      catchError(() => of(null)),
    );
};
