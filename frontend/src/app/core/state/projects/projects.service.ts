import { Injectable } from '@angular/core';
import {
  catchError,
  tap,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import {
  applyTransaction,
  ID,
} from '@datorama/akita';
import { HttpClient } from '@angular/common/http';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { NotificationsService } from 'core-app/shared/components/notifications/notifications.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ProjectsQuery } from 'core-app/core/state/projects/projects.query';
import { Apiv3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { collectionKey } from 'core-app/core/state/collection-store';
import { ProjectsStore } from './projects.store';
import { Project } from './project.model';

@Injectable()
export class ProjectsResourceService {
  protected store = new ProjectsStore();

  readonly query = new ProjectsQuery(this.store);

  private get projectsPath():string {
    return this
      .apiV3Service
      .projects
      .path;
  }

  constructor(
    private http:HttpClient,
    private apiV3Service:APIV3Service,
    private notifications:NotificationsService,
  ) {
  }

  fetchProjects(params:Apiv3ListParameters):Observable<IHALCollection<Project>> {
    const collectionURL = collectionKey(params);

    return this
      .http
      .get<IHALCollection<Project>>(this.projectsPath + collectionURL)
      .pipe(
        tap((events) => {
          applyTransaction(() => {
            this.store.add(events._embedded.elements);
            this.store.update(({ collections }) => (
              {
                collections: {
                  ...collections,
                  [collectionURL]: {
                    ids: events._embedded.elements.map((el) => el.id),
                  },
                },
              }
            ));
          });
        }),
        catchError((error) => {
          this.notifications.addError(error);
          throw error;
        }),
      );
  }

  update(id:ID, project:Partial<Project>):void {
    this.store.update(id, project);
  }

  modifyCollection(params:Apiv3ListParameters, callback:(collection:ID[]) => ID[]):void {
    const key = collectionKey(params);
    this.store.update(({ collections }) => (
      {
        collections: {
          ...collections,
          [key]: {
            ...collections[key],
            ids: [...callback(collections[key]?.ids || [])],
          },
        },
      }
    ));
  }
}
