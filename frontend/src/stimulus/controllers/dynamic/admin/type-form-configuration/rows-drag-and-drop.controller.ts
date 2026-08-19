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

import TypeFormConfigurationDragAndDropController from './drag-and-drop.controller';
import type { Drake } from 'dragula';
import type { DomAutoscrollService } from 'core-app/shared/helpers/drag-and-drop/dom-autoscroll.service';

interface ReconnectableDragAndDropController {
  drake:Drake|null;
  autoscroll:DomAutoscrollService|null;
  connect:() => void;
}

export default class TypeFormConfigurationRowsDragAndDropController extends TypeFormConfigurationDragAndDropController {
  static targets = ['container', 'scrollContainer'];

  async drop(el:Element, target:Element, source:Element|null, sibling:Element|null) {
    await super.drop(el, target, source, sibling);

    // After drop completes and DOM updates, reinitialize dragula
    setTimeout(() => {
      if (!this.element.isConnected) return;

      const parent = this as unknown as ReconnectableDragAndDropController;
      if (parent.drake) {
        parent.drake.destroy();
        parent.drake = null;
      }
      if (parent.autoscroll) {
        parent.autoscroll.destroy();
        parent.autoscroll = null;
      }
      super.connect();
    }, 300);
  }
}
