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
 *
 */

import { Controller } from '@hotwired/stimulus';

export default class ProjectController extends Controller {
  static targets = [
    'descriptionToggle',
    'projectRow',
    'descriptionRow',
  ];

  declare readonly descriptionToggleTargets:HTMLAnchorElement[];
  declare readonly projectRowTargets:HTMLTableRowElement[];
  declare readonly descriptionRowTargets:HTMLTableRowElement[];

  toggleDescription({ target, params: { projectId } }:{ target:HTMLAnchorElement, params:{ projectId:number } }) {
    const toggledTrigger = target;
    const otherTrigger = this.descriptionToggleTargets.find((trigger) => trigger !== toggledTrigger);
    // The projectId action parameter is automatically typecast to Number
    // and to compare it with a data attribute it needs to be converted to
    // a string.
    const clickedProjectRow = this.projectRowTargets.find((projectRow) => projectRow.getAttribute('data-project-id') === projectId.toString());
    const projectDescriptionRow = this.descriptionRowTargets.find((descriptionRow) => descriptionRow.getAttribute('data-project-id') === projectId.toString());

    if (clickedProjectRow && projectDescriptionRow) {
      clickedProjectRow.classList.toggle('-no-highlighting');
      clickedProjectRow.classList.toggle('-expanded');
      projectDescriptionRow.classList.toggle('-expanded');

      this.setAriaLive(projectDescriptionRow);
    }

    if (otherTrigger) {
      otherTrigger.focus();
    }
  }

  private setAriaLive(descriptionRow:HTMLElement) {
    if (descriptionRow.classList.contains('-expanded')) {
      descriptionRow.setAttribute('aria-live', 'polite');
    } else {
      descriptionRow.removeAttribute('aria-live');
    }
  }
}
