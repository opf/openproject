//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
