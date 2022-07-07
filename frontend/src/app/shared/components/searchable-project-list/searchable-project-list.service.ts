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

  private handleKeyNavigation(upwards = false):void {
    const focused = document.activeElement as HTMLElement|undefined;
    const items = document.querySelectorAll(`[data-list-action-selector='${projectListActionSelector}']`);

    // If the current focus is within a list action, move focus in direction
    if (focused?.closest(projectListActionSelector)) {
      this.moveFocus(focused, upwards);
      return;
    }

    // If we're moving down, select first
    if (!upwards) {
      const first = document.querySelector<HTMLElement>(projectListActionSelector);
      first?.focus();
    }
  }

  private moveFocus(source:Element, upwards = false):void {
    const activeItem = source.closest(projectListActionSelector) as HTMLElement;
    let nextContainer:Element|null|undefined;

    if (upwards) {
      nextContainer = activeItem.previousElementSibling || activeItem.closest('li')?.previousElementSibling;
    } else {
      nextContainer = activeItem?.nextElementSibling || activeItem.closest('li')?.nextElementSibling;
    }

    const target = nextContainer?.querySelector<HTMLElement>(projectListActionSelector);
    target?.focus();
  }

  onKeydown(event:KeyboardEvent):void {
    switch (event.keyCode) {
      case KeyCodes.UP_ARROW:
        this.handleKeyNavigation(true);
        break;
      case KeyCodes.DOWN_ARROW:
        this.handleKeyNavigation(false);
        break;
      default:
        break;
    }
  }
}
