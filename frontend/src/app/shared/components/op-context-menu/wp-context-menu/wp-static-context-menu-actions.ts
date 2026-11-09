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
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

export function isCopyIdAction(key:string):boolean {
  return key === 'copy_alphanumeric_id_to_clipboard';
}

export function copyIdActionLabel(workPackage:WorkPackageResource):string {
  return I18n.t('js.button_copy_id', { id: workPackage.displayId });
}

export const PERMITTED_CONTEXT_MENU_ACTIONS:WorkPackageAction[] = [
  {
    key: 'copy_link_to_clipboard',
    icon: 'icon-clipboard',
    link: 'id',
  },
  {
    key: 'copy_alphanumeric_id_to_clipboard',
    icon: 'icon-clipboard',
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
    key: 'delete',
    link: 'delete',
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
];
