import { IProjectAutocompleteItemTree } from './project-autocomplete-item';

// Recursively sort project children and their children by name
export const recursiveSort = (projects:IProjectAutocompleteItemTree[]):IProjectAutocompleteItemTree[] => projects
  .map((project) => ({
    ...project,
    children: recursiveSort(project.children),
  }))
  .sort((a, b) => a.name.localeCompare(b.name));
