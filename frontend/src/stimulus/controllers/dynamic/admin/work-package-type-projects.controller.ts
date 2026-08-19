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

import { Controller } from '@hotwired/stimulus';

export default class WorkPackageTypeProjectsController extends Controller {
  static targets = [
    'selectedProjects',
    'treeView',
  ];

  static values = {
    initiallySelectedProjects: String,
  };

  declare initiallySelectedProjectsValue:string;

  declare readonly treeViewTarget:HTMLElement;

  declare readonly selectedProjectsTarget:HTMLInputElement;

  connect():void {
    this.addProjectIds(this.initiallySelectedProjectsValue.split(','));
  }

  updateSelectedProjects(ev:PointerEvent):void {
    const target = ev.target;
    if (!this.isHTMLElement(target)) {
      return;
    }

    const projectItem = target.closest('.TreeViewItemContent');
    if (!this.isHTMLElement(projectItem)) {
      return;
    }

    const projectId = projectItem.dataset.projectId;
    const checked = projectItem.ariaChecked;

    if (!projectId || !checked) {
      return;
    }

    if (checked === 'false') {
      // 'false' means it was now changed to true -> selected
      this.addProjectIds([projectId]);
    } else {
      this.removeProjectIds([projectId]);
    }
  }

  private addProjectIds(ids:string[]):void {
    if (!this.selectedProjectsTarget) {
      return;
    }

    const currentIds = JSON.parse(this.selectedProjectsTarget.value) as string[];
    const distinctIds = [...new Set(currentIds), ...new Set(ids)].filter((id) => id.length > 0);
    this.selectedProjectsTarget.value = JSON.stringify(distinctIds);
  }

  private removeProjectIds(ids:string[]):void {
    if (!this.selectedProjectsTarget) {
      return;
    }

    const currentIds = JSON.parse(this.selectedProjectsTarget.value) as string[];
    const newIds = currentIds.filter((id) => !ids.includes(id));
    this.selectedProjectsTarget.value = JSON.stringify(newIds);
  }

  private isHTMLElement(obj:unknown):obj is HTMLElement {
    return obj instanceof HTMLElement;
  }
}
