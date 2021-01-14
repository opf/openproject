import { Injectable } from '@angular/core';
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {Observable} from "rxjs";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {map} from "rxjs/operators";

@Injectable({
  providedIn: 'root',
})
export class PermissionsService {
  constructor(
    private apiV3Service:APIV3Service,
    private currentProjectService:CurrentProjectService,
  ) { }

  canInviteUsersToProject(projectId = this.currentProjectService.id):Observable<boolean> {
    const filters = [['id', '=', [projectId]]];

    return this.apiV3Service
      .memberships
      .available_projects
      .list({filters})
      .pipe(map(collection => {
        console.log('collection: ', collection.elements.length, collection);
        return !!collection.elements.length;
      }));
  }
}
