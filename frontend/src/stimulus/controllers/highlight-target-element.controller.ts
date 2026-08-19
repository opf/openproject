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

import { ApplicationController } from 'stimulus-use';

export default class HighlightTargetElementController extends ApplicationController {
  connect() {
    this.handleInitialScroll();
  }

  private handleInitialScroll() {
    const hash = window.location.hash;

    if (hash?.startsWith('#')) {
      try {
        const el = document.querySelector<HTMLElement>(hash);
        if (el) {
          this.scrollIntoView(el);
          this.addOutsideClickHandler();
        }
      } catch (e) {
        // This is very likely an invalid selector such as a Google Analytics tag.
        // We can safely ignore this and just not scroll in this case.
        // Still log the error so one can confirm the reason there is no scrolling.
        if (e instanceof Error) {
          console.warn(`Could not scroll to given location hash: ${hash} ( ${e.message})`);
        }
      }
    }
  }

  private scrollIntoView(el:HTMLElement) {
    setTimeout(() => {
      el?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 25);
  }

  private addOutsideClickHandler() {
    setTimeout(() => {
      document.addEventListener('click', () => {
        const newLocation = window.location.href.replace(window.location.hash, '');
        window.location.hash = '';
        window.history.replaceState(null, 'Remove anchor', newLocation);
      }, { once: true });
    });
  }
}
