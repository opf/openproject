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

import { ApplicationController } from 'stimulus-use';

export default class KeepScrollPositionController extends ApplicationController {
  static targets = ['triggerButton'];

  declare triggerButtonTarget:HTMLLinkElement;

  connect() {
    super.connect();

    window.addEventListener('turbo:load', this.autoscrollToLastKnownPosition.bind(this));
    window.addEventListener('DOMContentLoaded', this.autoscrollToLastKnownPosition.bind(this));
  }

  disconnect() {
    super.disconnect();
  }

  triggerButtonTargetConnected() {
    this.triggerButtonTarget.addEventListener('click', this.rememberCurrentScrollPosition.bind(this));
  }

  rememberCurrentScrollPosition() {
    const currentPosition = document.getElementById('content-body')?.scrollTop;

    if (currentPosition !== undefined) {
      sessionStorage.setItem(this.scrollPositionKey(), currentPosition.toString());
    }
  }

  autoscrollToLastKnownPosition() {
    const lastKnownPos = sessionStorage.getItem(this.scrollPositionKey());
    if (lastKnownPos) {
      const content = document.getElementById('content-body');

      if (content) {
        setTimeout(() => {
          content.scrollTop = parseInt(lastKnownPos, 10);
        }, 25); // Magic number - unsure why, but fixes the issue of not scrolling on reload
      }
    }

    sessionStorage.removeItem(this.scrollPositionKey());
  }

  private scrollPositionKey():string {
    return `${window.location.pathname}/scrollPosition`;
  }
}
