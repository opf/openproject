import { IProject } from 'core-app/core/state/projects/project.model';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { IProjectData } from 'core-app/shared/components/searchable-project-list/project-data';

const UNDISCLOSED_ANCESTOR = 'urn:openproject-org:api:v3:undisclosed';

// Helper function that recursively inserts a project into the hierarchy at the right place
export const insertInList = (
  projects:IProject[],
  project:IProject,
  list:IProjectData[],
  ancestors:IHalResourceLink[],
):IProjectData[] => {
  // In a set of projects, some ancestors may be undisclosed. The client then knows of its existence
  // but knows nothing more than that. Those projects receive an 'undisclosed' urn for their href. For building
  // the project hierarchy, they can be ignored.
  const visibleAncestors = ancestors.filter((ancestor) => ancestor.href !== UNDISCLOSED_ANCESTOR);

  if (!visibleAncestors.length) {
    return [
      ...list,
      {
        id: project.id,
        name: project.name,
        href: project._links.self.href,
        disabled: false,
        children: [],
        position: 0,
      },
    ];
  }

  const ancestorHref = visibleAncestors[0].href;
  const ancestor:IProjectData|undefined = list.find((projectInList) => projectInList.href === ancestorHref);

  if (ancestor) {
    ancestor.children = insertInList(
      projects,
      project,
      ancestor.children,
      visibleAncestors.slice(1),
    );
    return [...list];
  }

  const ancestorProject = projects.find((projectInList) => projectInList._links.self.href === ancestorHref);
  if (!ancestorProject) {
    return [...list];
  }

  return [
    ...list,
    {
      id: ancestorProject.id,
      name: ancestorProject.name,
      href: ancestorProject._links.self.href,
      disabled: true,
      children: insertInList(projects, project, [], visibleAncestors.slice(1)),
      position: 0,
    },
  ];
};
