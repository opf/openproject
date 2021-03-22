import { Injectable } from '@angular/core';
import { APIV3Service } from 'core-app/modules/apiv3/api-v3.service';
import { Observable } from 'rxjs';
import { CurrentProjectService } from 'core-components/projects/current-project.service';
import { map } from 'rxjs/operators';
import { FilterOperator } from 'core-components/api/api-v3/api-v3-filter-builder';

@Injectable({
  providedIn: 'root',
})
export class PermissionsService {
  constructor(
    private apiV3Service:APIV3Service,
    private currentProjectService:CurrentProjectService,
  ) { }

  canInviteUsersToProject(projectId = this.currentProjectService.id!):Observable<boolean> {
    // TODO: Remove/Fix this typing issue
    const filters:[string, FilterOperator, string[]][] = [['id', '=', [projectId]]];

    return this.apiV3Service
      .memberships
      .available_projects
      .list({ filters })
      .pipe(map(collection => !!collection.elements.length));
  }
}
