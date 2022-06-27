import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import {
  IProjectAutocompleteItem,
  IProjectAutocompleteItemTree,
} from './project-autocomplete-item';

const insertProjectWithAncestors = (
  tree:IProjectAutocompleteItemTree[],
  project:IProjectAutocompleteItem,
  ancestors:IHalResourceLink[],
):IProjectAutocompleteItemTree[] => {
  // The project has no ancestors, thus it can become a part of the tree right away.
  if (!ancestors.length) {
    return [
      ...tree,
      {
        ...project,
        children: [],
      },
    ];
  }

  const ancestorToFind = ancestors[0];
  const ancestorInTree = tree.find((leaf) => leaf.href === ancestorToFind.href);

  if (ancestorInTree) {
    return tree.map((item) => (item === ancestorInTree
      ? { ...item, children: insertProjectWithAncestors(item.children, project, ancestors.slice(1)) }
      : { ...item }));
  }

  return [
    ...tree,
    {
      id: idFromLink(ancestorToFind.href),
      name: ancestorToFind.title,
      href: ancestorToFind.href,
      disabled: true,
      children: insertProjectWithAncestors([], project, ancestors.slice(1)),
    },
  ];
};

export const buildTree = (
  projects:IProjectAutocompleteItem[],
):IProjectAutocompleteItemTree[] => projects.reduce(
  // The ancestors are listed from direct parent up to root. We'll build a tree structure for these ancestors here.
  // Some might already exist from other children that added them to the tree, or because they were part of the result
  // list themselves. However, if they're not available yet we'll need to generate them.
  (tree, project) => insertProjectWithAncestors(tree, project, project.ancestors),
  [],
);
