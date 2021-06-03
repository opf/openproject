import { AbstractControl } from "@angular/forms";
import { CurrentUserService } from "core-app/modules/current-user/current-user.service";
import { of } from "rxjs";
import { catchError, map, take } from "rxjs/operators";

export const ProjectAllowedValidator = (currentUserService:CurrentUserService) => {
  return (control: AbstractControl) => {
    return currentUserService.hasCapabilities$('memberships/update', control.value.idFromLink).pipe(
      take(1),
      map(isAllowed => isAllowed ? null : { lackingPermission: true }),
      catchError(() => of(null))
    )
  }
}
