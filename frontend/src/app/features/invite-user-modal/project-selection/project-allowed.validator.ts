import { AbstractControl } from "@angular/forms";
import { of } from "rxjs";
import { catchError, map, take } from "rxjs/operators";
import { CurrentUserService } from "core-app/core/current-user/current-user.service";

export const ProjectAllowedValidator = (currentUserService:CurrentUserService) => {
  return (control: AbstractControl) => {
    return currentUserService.hasCapabilities$('memberships/create', control.value.idFromLink).pipe(
      take(1),
      map(isAllowed => isAllowed ? null : { lackingPermission: true }),
      catchError(() => of(null))
    )
  }
}