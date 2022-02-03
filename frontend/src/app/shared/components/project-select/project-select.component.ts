import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
} from '@angular/core';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';
import { ApiV3ListFilter, ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { map } from 'rxjs/operators';
import { IProject } from 'core-app/core/state/projects/project.model';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { ID } from '@datorama/akita';

export interface IProjectData {
  id: ID;
  href: string;
  name: string;
  children: IProjectData[];
};

@Component({
  selector: 'op-project-select',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-select.component.html',
  styleUrls: ['./project-select.component.sass'],
})
export class OpProjectSelectComponent implements OnInit {
  public opened = false;
  public query = '';
  public selectedProjects:ID[] = [];

  public projects$ = this.projectsResourceService
    .query
    .selectAll()
    .pipe(
      map(projects => projects
        .sort((a, b) => a._links.ancestors.length - b._links.ancestors.length)
        .map(p => ({...p}))
        .reduce((list, project) => {
          const { ancestors } = project._links;

          const insertInList = (project: IProject, list: IProjectData[], ancestors:IHalResourceLink[]) => {
            if (!ancestors.length) {
              return [
                ...list,
                {
                  id: project.id,
                  name: project.name,
                  href: project._links.self.href,
                  children: [],
                },
              ];
            }

            const ancestorHref = ancestors[0].href;
            const ancestor:IProjectData|undefined = list.find(projectInList => projectInList.href === ancestorHref);
            if (ancestor) {
              ancestor.children = insertInList(project, ancestor.children, ancestors.slice(1));
            }
            return list;
          }

          return insertInList(project, list, ancestors);
        }, [] as IProjectData[]),
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

  public toggleOpen() {
    this.opened = !this.opened;
    this.searchProjects();
  }

  public searchProjects() {
    this.projectsResourceService
      .fetchProjects(this.params)
      .subscribe();
  }

  public clearSelection() {
    this.selectedProjects = [];
  }

  public onSubmit() {
  }
}
