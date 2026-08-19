import { IProjectAutocompleteItem, IProjectAutocompleteItemTree } from './project-autocomplete-item';

export const flattenProjectTree = (
  projectTreeItems:IProjectAutocompleteItemTree[],
  depth = 0,
):IProjectAutocompleteItem[] => projectTreeItems.reduce(
  (fullList, projectTreeItem) => [
    ...fullList,
    {
      ...projectTreeItem,
      numberOfAncestors: depth,
      // The actual list of ancestors does not matter anymore from this point forward,
      // but to keep typing straightforward for consumers of this component that use mapResultsFn,
      // it is marked as required in the interface.
      ancestors: [],
    },
    ...flattenProjectTree(projectTreeItem.children, depth + 1),
  ],
  [],
);
