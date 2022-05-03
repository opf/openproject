import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  Component,
  HostBinding,
  OnInit,
} from '@angular/core';
import { HttpClient } from '@angular/common/http';
import {
  BehaviorSubject,
  combineLatest,
} from 'rxjs';
import {
  debounceTime,
  distinctUntilChanged,
  finalize,
  map,
  mergeMap,
  take,
} from 'rxjs/operators';

import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import {
  ApiV3ListFilter,
  ApiV3ListParameters,
  listParamsString,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackageViewIncludeSubprojectsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-include-subprojects.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { IProject } from 'core-app/core/state/projects/project.model';

import { IProjectData } from './project-data';
import { insertInList } from './insert-in-list';
import { recursiveSort } from './recursive-sort';
import { getPaginatedResults } from 'core-app/core/apiv3/helpers/get-paginated-results';

@Component({
  selector: 'op-project-include',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-include.component.html',
  styleUrls: ['./project-include.component.sass'],
})
export class OpProjectIncludeComponent extends UntilDestroyedMixin implements OnInit {
  @HostBinding('class.op-project-include') className = true;

  public text = {
    toggle_title: this.I18n.t('js.include_projects.toggle_title'),
    title: this.I18n.t('js.include_projects.title'),
    filter_all: this.I18n.t('js.include_projects.selected_filter.all'),
    filter_selected: this.I18n.t('js.include_projects.selected_filter.selected'),
    search_placeholder: this.I18n.t('js.include_projects.search_placeholder'),
    clear_selection: this.I18n.t('js.include_projects.clear_selection'),
    apply: this.I18n.t('js.include_projects.apply'),
    include_subprojects: this.I18n.t('js.include_projects.include_subprojects'),
  };

  public opened = false;

  public query$ = this.wpTableFilters.querySpace.query.values$();

  public displayModeOptions = [
    { value: 'all', title: this.text.filter_all },
    { value: 'selected', title: this.text.filter_selected },
  ];

  private _displayMode = 'all';

  public get displayMode():string {
    return this._displayMode;
  }

  public set displayMode(val:string) {
    this._displayMode = val;
    this.displayMode$.next(val);
  }

  public displayMode$ = new BehaviorSubject('all');

  private _searchText = '';

  public get searchText():string {
    return this._searchText;
  }

  public set searchText(val:string) {
    this._searchText = val;
    this.searchText$.next(val);
  }

  public searchText$ = new BehaviorSubject('');

  private _includeSubprojects = true;

  public get includeSubprojects():boolean {
    return this._includeSubprojects;
  }

  public set includeSubprojects(val:boolean) {
    this._includeSubprojects = val;
    this.includeSubprojects$.next(val);
  }

  public includeSubprojects$ = new BehaviorSubject(true);

  private _selectedProjects:string[] = [];

  public get selectedProjects():string[] {
    return this._selectedProjects;
  }

  public set selectedProjects(val:string[]) {
    this._selectedProjects = val;
    this.selectedProjects$.next(val);
  }

  public selectedProjects$ = new BehaviorSubject<string[]>([]);

  private projectsInFilter$ = this.wpTableFilters
    .live$()
    .pipe(
      this.untilDestroyed(),
      map((queryFilters) => {
        const projectFilter = queryFilters.find((queryFilter) => queryFilter._type === 'ProjectQueryFilter');
        const selectedProjectHrefs = ((projectFilter?.values || []) as HalResource[]).map((p) => p.href);
        const currentProjectHref = this.currentProjectService.apiv3Path;
        if (selectedProjectHrefs.includes(currentProjectHref)) {
          return selectedProjectHrefs;
        }
        const selectedPrjects = [...selectedProjectHrefs];
        if (currentProjectHref) {
          selectedPrjects.push(currentProjectHref);
        }
        return selectedPrjects;
      }),
    );

  public numberOfProjectsInFilter$ = this.projectsInFilter$.pipe(map((selected) => selected.length));

  public allProjects$ = new BehaviorSubject<IProject[]>([]);

  public projects$ = combineLatest([
    this.allProjects$,
    this.displayMode$.pipe(distinctUntilChanged()),
    this.includeSubprojects$,
    this.searchText$.pipe(debounceTime(200)),
  ])
    .pipe(
      debounceTime(50),
      mergeMap(([projects, displayMode, includeSubprojects, searchText]) => this.selectedProjects$.pipe(
        take(1),
        map((selected) => [projects, displayMode, includeSubprojects, searchText, selected]),
      )),
      map(
        ([projects, displayMode, includeSubprojects, searchText, selected]:[IProject[], string, boolean, string, string[]]) => projects
          .filter(
            (project) => {
              if (searchText.length) {
                const matches = project.name.toLowerCase().includes(searchText.toLowerCase()) || project.identifier.toLowerCase().includes(searchText.toLowerCase());

                if (!matches) {
                  return false;
                }
              }

              if (displayMode !== 'selected') {
                return true;
              }

              if (selected.includes(project._links.self.href)) {
                return true;
              }

              const hasSelectedAncestor = project._links.ancestors.reduce(
                (anySelected, ancestor) => anySelected || selected.includes(ancestor.href),
                false,
              );

              if (includeSubprojects && hasSelectedAncestor) {
                return true;
              }

              return false;
            },
          )
          .sort((a, b) => a._links.ancestors.length - b._links.ancestors.length)
          .reduce(
            (list, project) => {
              const { ancestors } = project._links;

              return insertInList(projects, project, list, ancestors);
            },
            [] as IProjectData[],
          ),
      ),
      map((projects) => recursiveSort(projects)),
    );

  public loading$ = new BehaviorSubject(false);

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

  constructor(
    readonly apiV3Service:ApiV3Service,
    readonly I18n:I18nService,
    readonly http:HttpClient,
    readonly wpTableFilters:WorkPackageViewFiltersService,
    readonly wpIncludeSubprojects:WorkPackageViewIncludeSubprojectsService,
    readonly halResourceService:HalResourceService,
    readonly currentProjectService:CurrentProjectService,
  ) {
    super();
  }

  public ngOnInit():void {
    this.query$
      .pipe(
        map((query) => query.includeSubprojects),
        distinctUntilChanged(),
      )
      .subscribe((includeSubprojects) => {
        this.includeSubprojects = includeSubprojects;
      });
  }

  public toggleIncludeSubprojects():void {
    this.wpIncludeSubprojects.setIncludeSubprojects(!this.wpIncludeSubprojects.current);
  }

  public toggleOpen():void {
    this.opened = !this.opened;

    if (this.opened) {
      this.loadAllProjects();
      this.projectsInFilter$
        .pipe(
          take(1),
        )
        .subscribe((selectedProjects) => {
          this.displayMode = 'all';
          this.searchText = '';
          this.selectedProjects = selectedProjects as string[];
        });
    }
  }

  public loadAllProjects():void {
    this.loading$.next(true);

    getPaginatedResults<IProject>(
      (params) => {
        const collectionURL = listParamsString({ ...this.params, ...params });
        return this.http.get<IHALCollection<IProject>>(this.apiV3Service.projects.path + collectionURL);
      },
    )
      .pipe(
        finalize(() => this.loading$.next(false)),
      )
      .subscribe((projects) => {
        this.allProjects$.next(projects);
      });
  }

  public clearSelection():void {
    this.selectedProjects = [this.currentProjectService.apiv3Path || ''];
  }

  public onSubmit(e:Event):void {
    e.preventDefault();

    // Replace actually also instantiates if it does not exist, which is handy here
    this.wpTableFilters.replace('project', (projectFilter:QueryFilterInstanceResource) => {
      const projectHrefs = this.selectedProjects;
      // eslint-disable-next-line no-param-reassign
      projectFilter.values = projectHrefs.map((href:string) => this.halResourceService.createHalResource({ href }, true));
    });

    this.wpIncludeSubprojects.update(this.includeSubprojects);

    this.close();
  }

  public close():void {
    this.opened = false;
  }
}
