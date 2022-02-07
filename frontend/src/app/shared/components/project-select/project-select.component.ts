import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
} from '@angular/core';
import {
  FormGroup,
  FormControl,
} from '@angular/forms';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';
import { ApiV3ListFilter, ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { combineLatest, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, map } from 'rxjs/operators';
import { IProject } from 'core-app/core/state/projects/project.model';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { ID } from '@datorama/akita';

export interface IProjectData {
  id: ID;
  href: string;
  name: string;
  found: boolean;
  children: IProjectData[];
};

// Helper function that recursively inserts a project into the hierarchy at the right place
const insertInList = (
  projects: IProject[],
  project: IProject,
  list: IProjectData[],
  ancestors:IHalResourceLink[],
):IProjectData[] => {
  if (!ancestors.length) {
    return [
      ...list,
      {
        id: project.id,
        name: project.name,
        href: project._links.self.href,
        found: true,
        children: [],
      },
    ];
  }

  const ancestorHref = ancestors[0].href;
  const ancestor:IProjectData|undefined = list.find(projectInList => projectInList.href === ancestorHref);

  if (ancestor) {
    ancestor.children = insertInList(projects, project, ancestor.children, ancestors.slice(1));
    return [...list];
  }

  const ancestorProject = projects.find(projectInList => projectInList._links.self.href === ancestorHref);
  if (!ancestorProject) {
    return [...list];
  }

  return [
    ...list,
    {
      id: ancestorProject.id,
      name: ancestorProject.name,
      href: ancestorProject._links.self.href,
      found: false,
      children: insertInList(projects, project, [], ancestors.slice(1)),
    },
  ]
}

const recursiveSort = (projects: IProjectData[]) => {
  projects
  .map(project => ({
    ...project,
    children: recursiveSort(project.children),
  }))
  .sort((a, b) => a.name.localeCompare(b.name)) 
}

@Component({
  selector: 'op-project-select',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-select.component.html',
  styleUrls: ['./project-select.component.sass'],
})
export class OpProjectSelectComponent implements OnInit {
  public opened = false;
  public displayMode = 'all';
  public displayMode$ = new Subject();
  public displayModeOptions = [
    { value: 'all', title: 'All projects' },
    { value: 'selected', title: 'Only selected' },
  ];

  public form = new FormGroup({
    selectedProjects: new FormControl([]),
    query: new FormControl(''),
  });

  public get query():string {
    return this.form.get('query')?.value || '';
  }

  public projects$ = combineLatest([
      this.form.valueChanges.pipe(
        map(value => value.query),
        distinctUntilChanged(),
        debounceTime(50),
      ),
      this.displayMode$.pipe(
        distinctUntilChanged(),
      ),
      this.projectsResourceService                
        .query
        .selectAll(),
    ])
    .pipe(
      map(([query, displayMode, projects]) => projects
        .filter((project) => {
          if (displayMode === 'selected' && !this.isChecked(project.id)) {
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
        }, [] as IProjectData[])
        .map(p => recursiveSort(p)),
      ),
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

    return {
      filters,
    };
  }

  constructor(
    readonly I18n:I18nService,
    readonly projectsResourceService:ProjectsResourceService,
  ) { }

  public ngOnInit() {}

  public isChecked(id:ID) {
    return this.form.get('selectedProjects')?.value.includes(id);
  }

  public toggleOpen() {
    this.opened = !this.opened;
    this.form.get('query')?.setValue('');
    this.searchProjects();
  }

  public searchProjects() {
    this.projectsResourceService
      .fetchProjects(this.params)
      .subscribe();
  }

  public clearSelection() {
    this.form.get('selectedProjects')?.setValue([]);
  }

  public onSubmit() {
  }
}
