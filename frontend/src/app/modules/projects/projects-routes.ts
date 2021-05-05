import { Ng2StateDeclaration, UIRouter } from "@uirouter/angular";
import { ProjectsComponent } from "core-app/modules/projects/components/projects/projects.component";
import { NewProjectComponent } from "core-app/modules/projects/components/new-project/new-project.component";
import {CopyProjectComponent} from "core-app/modules/projects/components/copy-project/copy-project.component";

export const PROJECTS_ROUTES:Ng2StateDeclaration[] = [
  {
    name: 'project_settings',
    parent: 'root',
    url: '/settings/generic/',
    component: ProjectsComponent,
  },
  {
    name: 'project_copy',
    parent: 'root',
    url: '/copy',
    component: CopyProjectComponent,
  },
  {
    name: 'new_project',
    url: '/projects/new?parent_id',
    component: NewProjectComponent,
  },
];

export function uiRouterProjectsConfiguration(uiRouter:UIRouter) {
  // Ensure projects/ are being redirected correctly
  // cf., https://community.openproject.com/wp/29754
  uiRouter.urlService.rules
    .when(
      new RegExp("^/projects/(.*)/settings/generic$"),
      match => `/projects/${match[1]}/settings/generic/`
    );
}