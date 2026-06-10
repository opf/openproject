import { Injectable, inject } from '@angular/core';
import {
  ApiV3ListFilter,
  ApiV3ListParameters,
  listParamsString,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { BehaviorSubject, combineLatest, forkJoin, of, Observable } from 'rxjs';
import { IProject } from 'core-app/core/state/projects/project.model';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { debounceTime, defaultIfEmpty, map, shareReplay, switchMap, take } from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { HttpClient } from '@angular/common/http';
import { ID } from '@datorama/akita';
import { IProjectData } from './project-data';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

const UNDISCLOSED_ANCESTOR = 'urn:openproject-org:api:v3:undisclosed';

@Injectable()
export class SearchableProjectListService {
  readonly http = inject(HttpClient);
  readonly apiV3Service = inject(ApiV3Service);
  readonly currentProjectService = inject(CurrentProjectService);
  readonly configurationService = inject(ConfigurationService);

  private _searchText = '';
  private searchText$ = new BehaviorSubject<string>('');
  private loadingEnabled$ = new BehaviorSubject<boolean>(false);
  public preloadProjectIds:string[] = [];

  get searchText():string {
    return this._searchText;
  }

  set searchText(val:string) {
    this._searchText = val;
    this.searchText$.next(val);
  }

  private get maximumPageSize():number {
    return this.configurationService.maximumApiV3PageSize;
  }

  private get preferredPageSize():number {
    return Math.min(300, this.maximumPageSize);
  }

  selectedItemID$ = new BehaviorSubject<ID|null>(null);
  queriedSearchText$ = this.searchText$.pipe(debounceTime(400));

  public readonly favoriteIds$:Observable<string[]> = this
    .apiV3Service
    .projects
    .signalled(
      ApiV3Filter('favorited', '=', true),
      [
        'elements/id',
      ],
      { pageSize: this.maximumPageSize.toString() },
    )
    .pipe(
      map((collection:IHALCollection<{ id:string|number }>) => collection._embedded.elements || []),
      map((elements) => elements.map((item) => item.id.toString())),
      defaultIfEmpty([]),
      shareReplay(1),
    );

  // Projects are fetched with a name filter on the search text, if one is provided. To provide good performance even on very
  // large instances (> 10,000 visible projects per user), we are not retrieving all projects eagerly, but limit the result to
  // a typical number of projects (preferredPageSize) and then ensure that certain projects are guaranteed to be present as well,
  // such as ancestors of visible projects and the user's favorite projects.
  // On small instances all projects are loaded in a single request, on large instances the typical ceiling is three requests,
  // though some edge cases (like MANY favorites) might require more than that.
  public readonly allProjects$ = combineLatest([
    this.queriedSearchText$,
    this.loadingEnabled$,
  ]).pipe(
    switchMap(([searchText, loadingEnabled]) => {
      if(loadingEnabled) {
        return this.favoriteIds$.pipe(map((favs) => [searchText, loadingEnabled as boolean, favs]));
      } else {
        return of([searchText, loadingEnabled as boolean, [] as string[]]);
      }
    }),
    switchMap(([searchText, loadingEnabled, favoriteIds]:[string,boolean,string[]]) => {
      if(!loadingEnabled) {
        return of([[] as IProject[], searchText, loadingEnabled as boolean, favoriteIds]);
      }

      const searchFilter:ApiV3ListFilter[] = [];
      if (searchText.length > 0) {
        searchFilter.push(['typeahead', '**', [searchText]]);
      }

      return this.fetchProjects(searchFilter)
                 .pipe(map((collection) => [collection._embedded.elements, searchText, loadingEnabled as boolean, favoriteIds]));
    }),
    switchMap(([projects, searchText, loadingEnabled, favoriteIds]:[IProject[],string,boolean,string[]]) => {
      // Those extra fetches are intended to make sure that a limited, unfiltered fetch does not leave out relevant projects
      // such as favorites or the preloaded projects (current project, selected projects)
      // in a filtered view, it's legitimate for them to be missing, thus we skip extra fetching if a search text is present
      if(!loadingEnabled || searchText.length > 0) {
        return of([projects, false]);
      }

      return this.pipeConcatProjects(projects, this.preloadProjectIds.concat(favoriteIds))
                 .pipe(map((p) => [p, true]));
    }),
    switchMap(([projects, enhancePreloadedProjects]:[IProject[],boolean]) => {
      // These can be fetched in parallel to ancestors, since they share ancestors with preloadProjectIds entries and thus
      // can't add new ancestors to the tree
      const extraFetches:Observable<IHALCollection<IProject>>[] = [];
      const allProjectsLoaded = projects.length < this.preferredPageSize;
      if(enhancePreloadedProjects && !allProjectsLoaded) {
        if(this.preloadProjectIds.length > 0) {
          const fetchChildren = this.fetchProjects([['ancestor', '=', this.preloadProjectIds]]);
          extraFetches.push(fetchChildren);
        }
        const parents = this.extractParents(projects, this.preloadProjectIds);
        if(parents.length > 0) {
          const fetchSiblings = this.fetchProjects([['parent_id', '=', parents]]);
          extraFetches.push(fetchSiblings);
        }
      }
      return this.pipeConcatProjects(projects, this.extractAncestors(projects), extraFetches);
    })
  );

  /** Causes fetching of a new project list and enables reloads of the project list, when the searchText changes. */
  public enableLoading():void {
    this.loadingEnabled$.next(true);
  }

  /** Disables reloads of the project list, when the searchText changes, an empty result will be returned instead. */
  public disableLoading():void {
    this.loadingEnabled$.next(false);
  }

  private params(additionalFilters:ApiV3ListFilter[], pageSize?:number):ApiV3ListParameters {
    const filters:ApiV3ListFilter[] = [
      ...additionalFilters,
      ['active', '=', ['t']],
    ];

    return {
      filters,
      pageSize: pageSize ?? this.preferredPageSize,
      select: [
        'elements/id',
        'elements/name',
        'elements/identifier',
        'elements/self',
        'elements/ancestors',
        'elements/_type'
      ],
      sortBy: [['lft', 'asc']],
    };
  }

  onKeydown(event:KeyboardEvent, projects:IProjectData[]):void {
    this.selectedItemID$
      .pipe(take(1))
      .subscribe((activeID) => {
        switch (event.key) {
          case 'ArrowUp':
            event.preventDefault();
            this.selectPreviousResult(activeID, projects);
            break;
          case 'ArrowDown':
            event.preventDefault();
            this.selectNextResult(activeID, projects);
            break;
          case 'Enter':
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
      for (const project of projects) {
        if (!project.disabled) {
          return project.id;
        }

        const childFound = findFirstNonDisabledID(project.children);
        if (childFound !== null) {
          return childFound;
        }
      }

      return null;
    };

    this.selectedItemID$.next(findFirstNonDisabledID(projects));
  }

  private selectPreviousResult(activeID:ID|null, allProjects:IProjectData[]):void {
    if (activeID === null) {
      return;
    }

    const findLastChild = (project:IProjectData):IProjectData => {
      if (project.children.length) {
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
    listParent?.querySelector<HTMLElement>('.spot-list--item-action_active')?.click();
    (focused as HTMLElement)?.focus();
  }

  /**
   * Fetches projects according to extraIds and appends them to projects. Fetching will only be performed for IDs that
   * are not already present in projects.
   * @param {IProject[]} projects - The initial projects that new fetches will be appended to
   * @param {string[]} concatIds - A list of project IDs that identifies projects that shall be appended
   */
  private pipeConcatProjects(projects:IProject[], concatIds:string[], extraFetches:Observable<IHALCollection<IProject>>[] = []) {
    const existingIds = this.extractIds(projects);
    concatIds = concatIds.filter((id) => !existingIds.has(id));

    for(let sliceStart = 0; sliceStart < concatIds.length; sliceStart += this.maximumPageSize) {
      const extraFilter = [['id', '=', concatIds.slice(sliceStart, sliceStart + this.maximumPageSize)]] as ApiV3ListFilter[];
      extraFetches.push(
        this.fetchProjects(extraFilter, this.maximumPageSize)
      );
    }

    if(extraFetches.length === 0) {
      return of(projects);
    }

    return forkJoin(extraFetches).pipe(
      map((collections) => collections.map((collection) => collection._embedded.elements)),
      map((collections) => projects.concat(...collections)),
      map((allProjects) => _.uniqBy(allProjects, (p) => p.id)),
    );
  }

  private fetchProjects(filters:ApiV3ListFilter[] = [], pageSize?:number):Observable<IHALCollection<IProject>> {
    const query = listParamsString(this.params(filters, pageSize));
    return this.http.get<IHALCollection<IProject>>(this.apiV3Service.projects.path + query);
  }

  private extractIds(projects:IProject[]):Set<string> {
    return new Set<string>(projects.map((p) => p.id.toString()));
  }

  private extractAncestors(projects:IProject[]):string[] {
    const ancestors = new Set<string>();
    projects.forEach((p) => p._links.ancestors.forEach((a) => ancestors.add(a.href)));

    // FIXME: Once we target ECMA Script 2025, we can and should use ancestors.values().filter(...)
    return [...ancestors.values()].filter((s) => s !== UNDISCLOSED_ANCESTOR).map((s) => s.split('/').pop()!);
  }

  private extractParents(projects:IProject[], childIds:string[]):string[] {
    const parents = new Set<string>();
    for(const p of projects.filter((p) => childIds.includes(p.id.toString()))) {
      const parent = p._links.ancestors[p._links.ancestors.length - 1];
      if(parent) {
        parents.add(parent.href);
      }
    }

    // FIXME: Once we target ECMA Script 2025, we can and should use parents.values().filter(...)
    return [...parents.values()].filter((s) => s !== UNDISCLOSED_ANCESTOR).map((s) => s.split('/').pop()!);
  }
}
