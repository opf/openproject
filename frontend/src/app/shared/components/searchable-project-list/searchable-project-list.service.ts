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
import { finalize, take } from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HttpClient } from '@angular/common/http';
import { KeyCodes } from 'core-app/shared/helpers/keyCodes.enum';
import { ID } from '@datorama/akita';
import { IProjectData } from './project-data';

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

  activeItemID$ = new BehaviorSubject<ID>(0);

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

  onKeydown(event:KeyboardEvent, projects:IProjectData[]):void {
    this.activeItemID$
      .pipe(take(1))
      .subscribe((activeID) => {
        switch (event.keyCode) {
          case KeyCodes.UP_ARROW:
            event.preventDefault();
            this.selectPreviousResult(activeID, projects);
            break;
          case KeyCodes.DOWN_ARROW:
            event.preventDefault();
            this.selectNextResult(activeID, projects);
            break;
          case KeyCodes.ENTER:
            event.stopPropagation();
            event.preventDefault();
            this.activateSelectedResult(event);
            break;
        }
      });
  }

  public resetActiveResult(id:ID) {
    this.activeItemID$.next(id);
  }

  private selectPreviousResult(id:ID, projects:IProjectData[]) {
    const findLastChild = (project:IProjectData):IProjectData => {
      if (project?.children?.length) {
        return findLastChild(project.children[project.children.length - 1]);
      }
      
      return project;
    };

    const findPreviousID = (projects:IProjectData[], parent?:IProjectData):ID|null => { 
      for (let i = 0; i < projects.length; i++) {
        if (projects[i].id === id) {
          const previous = findLastChild(projects[i - 1]) || projects[i - 1] || parent;
          return previous?.id || null;
        }

        const previous = findPreviousID(projects[i].children, projects[i]);
        if (previous !== null) {
          return previous;
        }
      }

      return null;
    };

    const foundPreviousID = findPreviousID(projects);
    this.activeItemID$.next(foundPreviousID || projects[0]?.id || 0); 
  }

  private selectNextResult(id:ID, projects:IProjectData[]) {
    const findNextID = (projects:IProjectData[], nextParent?:IProjectData):ID|null => { 
      for (let i = 0; i < projects.length; i++) {
        if (projects[i].id === id) {
          const next = projects[i].children[0] || projects[i + 1] || nextParent;
          return next?.id || null;
        }

        const next = findNextID(projects[i].children, projects[i + 1] || nextParent);
        if (next !== null) {
          return next;
        }
      }

      return null;
    }

    const foundNextID = findNextID(projects);
    this.activeItemID$.next(foundNextID || projects[0]?.id || 0); 
  }

  private activateSelectedResult(event:KeyboardEvent) {
    const findSearchableListParent = (el:HTMLElement|null):HTMLElement|null => {
      if (!el) {
        return null;
      }

      if ("searchableListParent" in el.dataset) {
        return el;
      }

      return findSearchableListParent(el.parentElement);
    };

    const listParent = findSearchableListParent(event.currentTarget as HTMLElement);
    const focused = document.activeElement;
    (listParent?.querySelector('.spot-list--item-action_active') as HTMLElement)?.click();
    (focused as HTMLElement)?.focus();
  }
}
