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

  searchText$ = new BehaviorSubject('');

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
        finalize(() => setTimeout(() => this.fetchingProjects$.next(false))),
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
}
