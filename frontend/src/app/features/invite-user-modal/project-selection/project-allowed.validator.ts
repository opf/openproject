import { AbstractControl } from '@angular/forms';
import {
  Observable,
  of,
} from 'rxjs';
import { catchError, map, take } from 'rxjs/operators';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

export const ProjectAllowedValidator = (currentUserService:CurrentUserService) => (control:AbstractControl):Observable<null|{ lackingPermission:boolean }> => {
  const href = control.value?.href || control.value?.$links?.self.href;
  const id = href ? idFromLink(href) : control.value;
  return currentUserService.hasCapabilities$(
    'memberships/create',
    id,
  ).pipe(
    take(1),
    map((isAllowed) => (isAllowed ? null : { lackingPermission: true })),
    catchError(() => of(null)),
  );
};
