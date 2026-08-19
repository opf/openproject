import { IProjectData } from 'core-app/shared/components/searchable-project-list/project-data';

// Recursively sort project children and their children by name
export const recursiveSort = (projects:IProjectData[]):IProjectData[] => projects
  .map((project) => ({
    ...project,
    children: recursiveSort(project.children),
  }))
  .sort((a, b) => a.name.localeCompare(b.name));
