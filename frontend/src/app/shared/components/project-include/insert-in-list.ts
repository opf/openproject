import { IProject } from 'core-app/core/state/projects/project.model';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { IProjectData } from '../project-list/project-data';

// Helper function that recursively inserts a project into the hierarchy at the right place
export const insertInList = (
  projects:IProject[],
  project:IProject,
  list:IProjectData[],
  ancestors:IHalResourceLink[],
):IProjectData[] => {
  if (!ancestors.length) {
    return [
      ...list,
      {
        id: project.id,
        name: project.name,
        href: project._links.self.href,
        disabled: false,
        children: [],
      },
    ];
  }

  const ancestorHref = ancestors[0].href;
  const ancestor:IProjectData|undefined = list.find((projectInList) => projectInList.href === ancestorHref);

  if (ancestor) {
    ancestor.children = insertInList(projects, project, ancestor.children, ancestors.slice(1));
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
      children: insertInList(projects, project, [], ancestors.slice(1)),
    },
  ];
};
