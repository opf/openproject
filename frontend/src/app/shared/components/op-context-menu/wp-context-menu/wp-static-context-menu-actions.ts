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
  WorkPackageAction,
} from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

export function isCopyIdAction(key:string):boolean {
  return key === 'copy_alphanumeric_id_to_clipboard';
}

export function copyIdActionLabel():string {
  return I18n.t('js.button_copy_work_package_id');
}

export const PERMITTED_CONTEXT_MENU_ACTIONS:WorkPackageAction[] = [
  {
    key: 'copy_link_to_clipboard',
    icon: 'icon-clipboard',
    link: 'id',
  },
  {
    key: 'copy_alphanumeric_id_to_clipboard',
    icon: 'icon-code-tag',
    link: 'id',
  },
  {
    key: 'log_time',
    link: 'logTime',
    turboRequest: true,
  },
  {
    key: 'change_project',
    icon: 'icon-move',
    link: 'move',
  },
  {
    key: 'duplicate',
    icon: 'icon-duplicate',
    link: 'copy',
  },
  {
    key: 'copy_to_other_project',
    link: 'copy',
    icon: 'icon-project-types',
  },
  {
    key: 'generate_pdf',
    link: 'generate_pdf',
    icon: 'icon-export-pdf-with-descriptions',
    turboRequest: true,
  },
  {
    key: 'view_markdown',
    link: 'markdown',
    icon: 'icon-file-text',
  },
  {
    key: 'export-atom',
    link: 'atom',
  },
  {
    key: 'delete',
    link: 'delete',
  },
];

const GROUPED_ACTION_KEYS = {
  open: ['copy_link_to_clipboard', 'copy_alphanumeric_id_to_clipboard'],
  log: ['log_time', 'start_timer', 'stop_timer', 'log_costs', 'allocate_resource'],
  organize: [
    'edit',
    'move',
    'copy',
    'change_project',
    'duplicate',
    'copy_to_other_project',
    'relation-new-child',
    'hierarchy-outdent',
    'hierarchy-indent',
    'relation-precedes',
    'relation-follows',
    'relations',
  ],
  export: ['generate_pdf', 'view_markdown', 'export-atom'],
  configure: [],
  destroy: ['delete'],
} as const satisfies Record<string, readonly string[]>;

export type ContextMenuGroup = keyof typeof GROUPED_ACTION_KEYS;

const GROUP_ORDER = Object.keys(GROUPED_ACTION_KEYS) as ContextMenuGroup[];

function menuPosition(key:string):{ group:ContextMenuGroup, index:number } {
  for (const group of GROUP_ORDER) {
    const index = (GROUPED_ACTION_KEYS[group] as readonly string[]).indexOf(key);
    if (index !== -1) return { group, index };
  }
  return { group: 'organize', index: Number.MAX_SAFE_INTEGER };
}

function comparePositions(a:ReturnType<typeof menuPosition>, b:ReturnType<typeof menuPosition>):number {
  return GROUP_ORDER.indexOf(a.group) - GROUP_ORDER.indexOf(b.group) || a.index - b.index;
}

/** Orders actions by menu group; actions unknown to the grouping keep their relative order. */
export function sortContextMenuActions<T extends { key:string }>(actions:T[]):T[] {
  return actions
    .map((action) => ({ action, position: menuPosition(action.key) }))
    .sort((a, b) => comparePositions(a.position, b.position))
    .map(({ action }) => action);
}

/** Collects the items of a work package context menu by group and joins the groups with dividers. */
export class ContextMenuItemGroups {
  private readonly groups:Record<ContextMenuGroup, OpContextMenuItem[]> = {
    open: [],
    log: [],
    organize: [],
    export: [],
    configure: [],
    destroy: [],
  };

  addAction(key:string, item:OpContextMenuItem):void {
    const { group } = menuPosition(key);

    this.groups[group].push(group === 'destroy' ? { ...item, scheme: 'danger' } : item);
  }

  append(group:ContextMenuGroup, item:OpContextMenuItem):void {
    this.groups[group].push(item);
  }

  prepend(group:ContextMenuGroup, item:OpContextMenuItem):void {
    this.groups[group].unshift(item);
  }

  transform(change:(item:OpContextMenuItem) => OpContextMenuItem):void {
    GROUP_ORDER.forEach((group) => {
      this.groups[group] = this.groups[group].map(change);
    });
  }

  get items():OpContextMenuItem[] {
    return GROUP_ORDER
      .map((group) => this.groups[group])
      .filter((group) => group.length > 0)
      .flatMap((group, index) => (index === 0 ? group : [{ divider: true }, ...group]));
  }
}
