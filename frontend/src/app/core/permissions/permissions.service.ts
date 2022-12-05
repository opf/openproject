import { Injectable } from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { Observable, of } from 'rxjs';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { catchError, map } from 'rxjs/operators';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

@Injectable({
  providedIn: 'root',
})
export class PermissionsService {
  constructor(
    private apiV3Service:ApiV3Service,
    private currentProjectService:CurrentProjectService,
  ) { }

  canInviteUsersToProject(projectId = this.currentProjectService.id!):Observable<boolean> {
    // TODO: Remove/Fix this typing issue
    const filters:[string, FilterOperator, string[]][] = [['id', '=', [projectId]]];

    return this.apiV3Service
      .memberships
      .available_projects
      .list({ filters })
      .pipe(
        map((collection) => !!collection.elements.length),
        catchError((error) => {
          console.error(error);
          return of(false);
        }),
      );
  }
}
