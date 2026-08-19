/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
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

import { Controller } from '@hotwired/stimulus';
import { useMeta } from 'stimulus-use';
import { ViewPortServiceInterface } from './services/view-port-service';
import type IndexController from './index.controller';

export default class BaseController extends Controller implements ViewPortServiceInterface {
  static metaNames = ['csrf-token'];
  declare readonly csrfToken:string;

  indexOutlet:IndexController;

  connect() {
    useMeta(this, { suffix: false });
    this.indexOutlet = this.indexController;
  }

  // Viewport service convenience methods
  isMobile() { return this.indexOutlet.viewPortService.isMobile(); }
  isWithinNotificationCenter() { return this.indexOutlet.viewPortService.isWithinNotificationCenter(); }
  isWithinSplitScreen() { return this.indexOutlet.viewPortService.isWithinSplitScreen(); }
  isJournalsContainerScrolledToBottom() { return this.indexOutlet.viewPortService.isJournalsContainerScrolledToBottom(); }
  anchorScrollOffset() { return this.indexOutlet.viewPortService.anchorScrollOffset(); }

  get scrollableContainer() { return this.indexOutlet.viewPortService.scrollableContainer; }

  private get indexController() {
    const identifier = 'work-packages--activities-tab--index';
    const target = document.getElementById(identifier)!;

    return this.application.getControllerForElementAndIdentifier(target, identifier) as IndexController;
  }
}
