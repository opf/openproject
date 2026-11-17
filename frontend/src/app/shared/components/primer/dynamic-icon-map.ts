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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  checkIconData,
  chevronDownIconData,
  chevronRightIconData,
  chevronUpIconData,
  circleSlashIconData,
  clockIconData,
  columnsIconData,
  duplicateIconData,
  graphIconData,
  hashIconData,
  infoIconData,
  kebabHorizontalIconData,
  markdownIconData,
  moveToBottomIconData,
  moveToTopIconData,
  noteIconData,
  opArrowInIconData,
  opBudgetIconData,
  opColumnsLeftIconData,
  opColumnsRightIconData,
  opCopyToProjectIconData,
  opFileAtomIconData,
  opGroupIconData,
  opHierarchyIconData,
  opIndentIconData,
  opMoveIconData,
  opOutdentIconData,
  opPdfDescriptionIconData,
  opRelationFollowsIconData,
  opRelationNewChildIconData,
  opRelationsIconData,
  opViewFullscreenIconData,
  opViewSplitIconData,
  opWorkPackagesIconData,
  packageDependentsIconData,
  pasteIconData,
  pencilIconData,
  personAddIconData,
  sortAscIconData,
  sortDescIconData,
  starIconData,
  SVGData,
  trashIconData,
  triangleDownIconData,
  xCircleIconData,
  xIconData,
} from '@openproject/octicons-angular';

export const ICON_MAP = {
  'check': checkIconData,
  'chevron-down': chevronDownIconData,
  'chevron-right': chevronRightIconData,
  'chevron-up': chevronUpIconData,
  'circle-slash': circleSlashIconData,
  clock: clockIconData,
  columns: columnsIconData,
  duplicate: duplicateIconData,
  graph: graphIconData,
  hash: hashIconData,
  info: infoIconData,
  'kebab-horizontal': kebabHorizontalIconData,
  markdown: markdownIconData,
  'move-to-bottom': moveToBottomIconData,
  'move-to-top': moveToTopIconData,
  note: noteIconData,
  'op-arrow-in': opArrowInIconData,
  'op-budget': opBudgetIconData,
  'op-columns-left': opColumnsLeftIconData,
  'op-columns-right': opColumnsRightIconData,
  'op-copy-to-project': opCopyToProjectIconData,
  'op-file-atom': opFileAtomIconData,
  'op-group': opGroupIconData,
  'op-hierarchy': opHierarchyIconData,
  'op-indent': opIndentIconData,
  'op-move': opMoveIconData,
  'op-outdent': opOutdentIconData,
  'op-pdf-description': opPdfDescriptionIconData,
  'op-relation-follows': opRelationFollowsIconData,
  'op-relation-new-child': opRelationNewChildIconData,
  'op-relations': opRelationsIconData,
  'op-view-fullscreen': opViewFullscreenIconData,
  'op-view-split': opViewSplitIconData,
  'op-work-packages': opWorkPackagesIconData,
  'package-dependents': packageDependentsIconData,
  paste: pasteIconData,
  pencil: pencilIconData,
  'person-add': personAddIconData,
  'sort-asc': sortAscIconData,
  'sort-desc': sortDescIconData,
  star: starIconData,
  trash: trashIconData,
  'triangle-down': triangleDownIconData,
  x: xIconData,
  'x-circle': xCircleIconData,
} satisfies Record<string, SVGData>;

export type DynamicIconName = keyof typeof ICON_MAP;

export function isDynamicIconName(name:string):name is DynamicIconName {
  return Object.hasOwn(ICON_MAP, name);
}
