import { Injectable } from '@angular/core';
import {
  ApiV3ListFilter,
  ApiV3ListParameters,
  listParamsString,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { BehaviorSubject } from 'rxjs';
import { IProject } from 'core-app/core/state/projects/project.model';
import { getPaginatedResults } from 'core-app/core/apiv3/helpers/get-paginated-results';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { finalize } from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HttpClient } from '@angular/common/http';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { projectListActionSelector } from 'core-app/shared/components/project-list/project-list.component';

@Injectable()
export class SearchableProjectListService {
  private _searchText = '';

  get searchText():string {
    return this._searchText;
  }

  set searchText(val:string) {
    this._searchText = val;
    this.searchText$.next(val);
  }

  searchText$ = new BehaviorSubject<string>('');

  allProjects$ = new BehaviorSubject<IProject[]>([]);

  fetchingProjects$ = new BehaviorSubject(false);

  constructor(
    readonly http:HttpClient,
    readonly apiV3Service:ApiV3Service,
  ) { }

  public loadAllProjects():void {
    this.fetchingProjects$.next(true);

    getPaginatedResults<IProject>(
      (params) => {
        const collectionURL = listParamsString({ ...this.params, ...params });
        return this.http.get<IHALCollection<IProject>>(this.apiV3Service.projects.path + collectionURL);
      },
    )
      .pipe(
        finalize(() => this.fetchingProjects$.next(false)),
      )
      .subscribe((projects) => {
        this.allProjects$.next(projects);
      });
  }

  public get params():ApiV3ListParameters {
    const filters:ApiV3ListFilter[] = [
      ['active', '=', ['t']],
    ];

    return {
      filters,
      pageSize: -1,
      select: [
        'elements/id',
        'elements/name',
        'elements/identifier',
        'elements/self',
        'elements/ancestors',
        'total',
        'count',
        'pageSize',
      ],
    };
  }

  registerArrowNavigationOnItems():void {
    let currentIndex = -1;

    document.addEventListener('keydown', (event) => {
      // Todo: Instead of collecting the items every time, do it once at the beginning.
      //  Keep in mind that the list needs to be loaded first, and the list might change when searched
      const items = document.querySelectorAll(`[data-list-action-selector='${projectListActionSelector}']`);

      if (event.keyCode === KeyCodes.UP_ARROW) {
        // Decrease the counter
        currentIndex = currentIndex > 0 ? currentIndex -= 1 : 0;
      } else if (event.keyCode === KeyCodes.DOWN_ARROW) {
        // Increase counter
        currentIndex = currentIndex < items.length - 1 ? currentIndex += 1 : items.length - 1;
      } else {
        return;
      }

      (items[currentIndex] as HTMLElement).focus();
    });
  }

  destroyArrowNavigation():void {
    // Todo: Implement
  }
}
