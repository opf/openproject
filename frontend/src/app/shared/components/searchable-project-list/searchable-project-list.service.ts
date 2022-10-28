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
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

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

  selectedItemID$ = new BehaviorSubject<ID|null>(null);

  searchText$ = new BehaviorSubject<string>('');

  allProjects$ = new BehaviorSubject<IProject[]>([]);

  fetchingProjects$ = new BehaviorSubject(false);

  constructor(
    readonly http:HttpClient,
    readonly apiV3Service:ApiV3Service,
    readonly currentProjectService:CurrentProjectService,
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
    this.selectedItemID$
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
          default:
            break;
        }
      });
  }

  public resetActiveResult(projects:IProjectData[]):void {
    const findFirstNonDisabledID = (projects:IProjectData[]):ID|null => {
      for (let i = 0; i < projects.length; i++) {
        if (!projects[i].disabled) {
          return projects[i].id;
        }

        const childFound = findFirstNonDisabledID(projects[i].children);
        if (childFound !== null) {
          return childFound;
        }
      }

      return null;
    }

    this.selectedItemID$.next(findFirstNonDisabledID(projects));
  }

  private selectPreviousResult(activeID:ID|null, allProjects:IProjectData[]):void {
    if (activeID === null) {
      return;
    }

    const findLastChild = (project:IProjectData):IProjectData => {
      if (project?.children?.length) {
        return findLastChild(project.children[project.children.length - 1]);
      }

      return project;
    };

    const findPreviousID = (idOfCurrent:ID, projects:IProjectData[], parent?:IProjectData):ID|null => {
      for (let i = 0; i < projects.length; i++) {
        if (projects[i].id === idOfCurrent) {
          const previous = findLastChild(projects[i - 1]) || projects[i - 1] || parent;
          if (!previous) {
            return null;
          }

          if (previous.disabled) {
            return findPreviousID(previous.id, allProjects);
          }

          return previous.id;
        }

        const previous = findPreviousID(idOfCurrent, projects[i].children, projects[i]);
        if (previous !== null) {
          return previous;
        }
      }

      return null;
    };

    const foundPreviousID = findPreviousID(activeID, allProjects);
    if (foundPreviousID !== null) {
      this.selectedItemID$.next(foundPreviousID);
    } else {
      this.resetActiveResult(allProjects);
    }
  }

  private selectNextResult(activeID:ID|null, allProjects:IProjectData[]):void {
    if (activeID === null) {
      return;
    }

    const findNextID = (idOfCurrent:ID, projects:IProjectData[], nextParent?:IProjectData):ID|null => {
      for (let i = 0; i < projects.length; i++) {
        if (projects[i].id === idOfCurrent) {
          const next = projects[i].children[0] || projects[i + 1] || nextParent;
          if (!next) {
            return null;
          }

          if (next.disabled) {
            return findNextID(next.id, allProjects);
          }

          return next.id;
        }

        const next = findNextID(idOfCurrent, projects[i].children, projects[i + 1] || nextParent);
        if (next !== null) {
          return next;
        }
      }

      return null;
    };

    const foundNextID = findNextID(activeID, allProjects);
    if (foundNextID !== null) {
      this.selectedItemID$.next(foundNextID);
    } else {
      this.resetActiveResult(allProjects);
    }
  }

  private activateSelectedResult(event:KeyboardEvent):void {
    const findSearchableListParent = (el:HTMLElement|null):HTMLElement|null => {
      if (!el) {
        return null;
      }

      if ('searchableListParent' in el.dataset) {
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
