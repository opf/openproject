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

import {
  contextColumnIcon,
  contextMenuLinkClassName,
  OpTableAction,
} from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { opIconElement } from 'core-app/shared/helpers/op-icon-builder';

export class OpContextMenuTableAction extends OpTableAction {
  public readonly identifier = 'open-context-menu-action';

  private text = {
    linkTitle: this.I18n.t('js.label_open_context_menu'),
  };

  public buildElement() {
    const contextMenu = document.createElement('a');
    contextMenu.href = '#';
    contextMenu.classList.add(contextMenuLinkClassName, contextColumnIcon);
    contextMenu.title = this.text.linkTitle;
    contextMenu.appendChild(opIconElement('icon', 'icon-show-more-horizontal'));

    return contextMenu;
  }
}
