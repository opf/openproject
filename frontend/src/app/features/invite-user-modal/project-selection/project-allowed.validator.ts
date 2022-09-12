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
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';

export const ProjectAllowedValidator = (currentUser:CurrentUserService) => (control:AbstractControl):Observable<null|{ lackingPermission:boolean }> => {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
  const href = (control.value?.href || control.value?.$links?.self.href) as string;
  const id = (href ? idFromLink(href) : control.value) as string;
  return currentUser
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
