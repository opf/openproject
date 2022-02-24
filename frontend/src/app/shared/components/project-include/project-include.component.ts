import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  Component,
  HostBinding,
} from '@angular/core';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';
import {
  ApiV3ListFilter,
  ApiV3ListParameters,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  BehaviorSubject,
  combineLatest,
} from 'rxjs';
import {
  debounceTime,
  distinctUntilChanged,
  map,
  mergeMap,
  take,
} from 'rxjs/operators';
import { IProjectData } from './project-data';
import { insertInList } from './insert-in-list';
import { recursiveSort } from './recursive-sort';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { IProject } from 'core-app/core/state/projects/project.model';

@Component({
  selector: 'op-project-include',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-include.component.html',
  styleUrls: ['./project-include.component.sass'],
})
export class OpProjectIncludeComponent extends UntilDestroyedMixin {
  @HostBinding('class.op-project-include') className = true;

  public text = {
    toggle_title: this.I18n.t('js.include_projects.toggle_title'),
    title: this.I18n.t('js.include_projects.title'),
    filter_all: this.I18n.t('js.include_projects.selected_filter.all'),
    filter_selected: this.I18n.t('js.include_projects.selected_filter.selected'),
    search_placeholder: this.I18n.t('js.include_projects.search_placeholder'),
    clear_selection: this.I18n.t('js.include_projects.clear_selection'),
    apply: this.I18n.t('js.include_projects.apply'),
  };

  public opened = false;

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

  private _query = '';

  public get query():string {
    return this._query;
  }

  public set query(val:string) {
    this._query = val;
    this.query$.next(val);
  }

  public query$ = new BehaviorSubject('');

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

        return [
          ...selectedProjectHrefs,
          currentProjectHref,
        ];
      }),
    );

  public numberOfProjectsInFilter$ = this.projectsInFilter$.pipe(map((selected) => selected.length));

  public allProjects$ = this.projectsResourceService.query.selectAll();

  public projects$ = combineLatest([
    this.allProjects$,
    this.query$.pipe(distinctUntilChanged()),
    this.displayMode$.pipe(distinctUntilChanged()),
  ])
    .pipe(
      debounceTime(20),
      mergeMap(([projects, query, displayMode]) => this.selectedProjects$.pipe(
        take(1),
        map((selected) => [projects, query, displayMode, selected]),
      )),
      map(
        ([projects, query, displayMode, selected]:[IProject[], string, string, string[]]) => projects
          .filter(
            (project) => {
              if (displayMode === 'selected' && !selected.includes(project._links.self.href)) {
                return false;
              }

              if (query.length) {
                return project.name.toLowerCase().includes(query.toLowerCase()) || project.identifier.toLowerCase().includes(query.toLowerCase());
              }

              return true;
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

    hasProjects$ = this
    .projects$
    .pipe(
      distinctUntilChanged(),
      map((items) => items.length > 0),
      distinctUntilChanged(),
    );

  public get params():ApiV3ListParameters {
    const filters:ApiV3ListFilter[] = [
      ['active', '=', ['t']],
    ];

    if (this.query) {
      filters.push([
        'name_and_identifier',
        '~',
        [this.query],
      ]);
    }

    return { filters, pageSize: -1 };
  }

  constructor(
    readonly I18n:I18nService,
    readonly projectsResourceService:ProjectsResourceService,
    readonly wpTableFilters:WorkPackageViewFiltersService,
    readonly halResourceService:HalResourceService,
    readonly currentProjectService:CurrentProjectService,
  ) {
    super();
  }

  public toggleOpen():void {
    this.opened = !this.opened;
    this.searchProjects();
    this.projectsInFilter$
      .pipe(take(1))
      .subscribe((selectedProjects) => {
        this.displayMode = 'all';
        this.query = '';
        this.selectedProjects = selectedProjects as string[];
      });
  }

  public searchProjects():void {
    this.projectsResourceService
      .fetchProjects(this.params)
      .subscribe();
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

    this.close();
  }

  public close():void {
    this.opened = false;
  }
}
