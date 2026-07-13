/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import GenericDragAndDropController from '../generic-drag-and-drop.controller';
import { appendCollapsedState } from '../../../helpers/meetings-helpers';
import { hasUnsavedChanges } from '../../../helpers/meetings-helpers';

export default class extends GenericDragAndDropController {
  protected override buildData(el:Element, target:Element):FormData {
    const data = super.buildData(el, target);

    appendCollapsedState(data);

    return data;
  }

  override async drop(el:Element, target:Element, source:Element|null, sibling:Element|null) {
    if (hasUnsavedChanges()) {
      if (!window.confirm(I18n.t('js.text_are_you_sure_to_cancel'))) {
        this.cancelDrag();
        return;
      }
    }

    await super.drop(el, target, source, sibling);
  }
}
