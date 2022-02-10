import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  Component,
  HostBinding,
} from '@angular/core';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';
import { ApiV3ListFilter, ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { combineLatest, BehaviorSubject } from 'rxjs';
import { debounceTime, distinctUntilChanged, map, mergeMap, take } from 'rxjs/operators';
import { IProjectData } from './project-data';
import { insertInList } from './insert-in-list';
import { recursiveSort } from './recursive-sort';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { IProject } from 'core-app/core/state/projects/project.model';

@Component({
  selector: 'op-project-select',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-select.component.html',
  styleUrls: ['./project-select.component.sass'],
})
export class OpProjectSelectComponent extends UntilDestroyedMixin {
  @HostBinding('class.op-project-select') className = true;

  public opened = false;

  public displayModeOptions = [
    { value: 'all', title: 'All projects' },
    { value: 'selected', title: 'Only selected' },
  ];

  private _displayMode = 'all';
  public get displayMode() {
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
        map(selected => [projects, query, displayMode, selected])
      )),
      map(([projects, query, displayMode, selected]:[IProject[], string, string, string[]]) => projects
        .filter((project) => {
          if (displayMode === 'selected' && !selected.includes(project._links.self.href)) {
            return false;
          }

          if (query.length) {
            return project.name.toLowerCase().includes(query.toLowerCase()) || project.identifier.toLowerCase().includes(query.toLowerCase());
          }
          
          return true;
        })
        .sort((a, b) => a._links.ancestors.length - b._links.ancestors.length)
        .reduce((list, project) => {
          const { ancestors } = project._links;


          return insertInList(projects, project, list, ancestors);
        }, [] as IProjectData[]),
      ),
      map((projects) => recursiveSort(projects)),
    );

  public get params():ApiV3ListParameters {
    const filters: ApiV3ListFilter[] = [];
    if (this.query) {
      filters.push([
        'name_and_identifier',
        '~',
        [this.query],
      ]);
    }

    return { filters };
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

  public toggleOpen() {
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

  public searchProjects() {
    this.projectsResourceService
      .fetchProjects(this.params)
      .subscribe();
  }

  public clearSelection() {
    this.selectedProjects = [];
  }

  public onSubmit(e:Event) {
    e.preventDefault();

    // Replace actually also instantiates if it does not exist, which is handy here
    this.wpTableFilters.replace('project', (projectFilter:QueryFilterInstanceResource) => {
      const projectHrefs = this.selectedProjects;
      // eslint-disable-next-line no-param-reassign
      projectFilter.values = projectHrefs.map((href:string) => this.halResourceService.createHalResource({ href }, true));
    });

    this.close();
  }

  public close() {
    this.opened = false;
  }
}
