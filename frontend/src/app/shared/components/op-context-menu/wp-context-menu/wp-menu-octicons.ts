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

import type { DynamicIconName } from 'core-app/shared/components/primer/dynamic-icon-map';
import type { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

const WP_MENU_OCTICONS = {
  'icon-budget': 'op-budget',
  'icon-clipboard': 'paste',
  'icon-code-tag': 'hash',
  'icon-columns': 'columns',
  'icon-copy': 'duplicate',
  'icon-custom-fields': 'op-custom-fields',
  'icon-delete': 'trash',
  'icon-duplicate': 'duplicate',
  'icon-edit': 'pencil',
  'icon-export': 'download',
  'icon-export-atom': 'op-file-atom',
  'icon-export-pdf-with-descriptions': 'op-pdf-description',
  'icon-file-text': 'markdown',
  'icon-group-by': 'op-group',
  'icon-link': 'link',
  'icon-log_time': 'clock',
  'icon-move': 'op-move',
  'icon-paragraph-left': 'op-outdent',
  'icon-paragraph-right': 'op-indent',
  'icon-project-types': 'op-copy-to-project',
  'icon-relation-follows': 'op-relation-follows',
  'icon-relation-new-child': 'op-relation-new-child',
  'icon-relation-precedes': 'package-dependents',
  'icon-relations': 'op-relations',
  'icon-save': 'op-save',
  'icon-settings': 'gear',
  'icon-settings3': 'gear',
  'icon-sort-by': 'op-sort-by',
  'icon-time-tracking-start': 'play',
  'icon-time-tracking-stop': 'stop',
  'icon-user-plus': 'person-add',
  'icon-view-fullscreen': 'op-view-fullscreen',
  'icon-view-split': 'op-view-split',
  'icon-watched': 'eye',
} as const satisfies Record<`icon-${string}`, DynamicIconName>;

/** The Octicon for a legacy Spot icon class used by work package menu actions, if one is mapped. */
export function wpMenuOcticon(icon:string|undefined):DynamicIconName|undefined {
  return icon !== undefined && Object.hasOwn(WP_MENU_OCTICONS, icon)
    ? WP_MENU_OCTICONS[icon as keyof typeof WP_MENU_OCTICONS]
    : undefined;
}

/** Swaps the item's legacy icon class for its Octicon; an icon without a mapping is dropped. */
export function withOcticon(item:OpContextMenuItem):OpContextMenuItem {
  const { icon, ...rest } = item;
  const octicon = wpMenuOcticon(icon);
  return octicon ? { ...rest, octicon } : rest;
}
