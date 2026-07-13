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
import type { SelectPanelElement } from '@primer/view-components/app/components/primer/alpha/select_panel_element';
import WorkflowCheckboxStateController from './workflow-checkbox-state.controller';

/**
 * When the panel closes, it navigates to the workflow edit page with the selected role IDs.
 * Delegates dirty-state confirmation to the workflow-checkbox-state controller via an outlet.
 */
export default class WorkflowRoleSelectController extends Controller {
  static outlets = ['admin--workflow-checkbox-state'];
  static values = { baseUrl: String, currentRoleIds: Array };

  declare readonly adminWorkflowCheckboxStateOutlet:WorkflowCheckboxStateController;
  declare readonly hasAdminWorkflowCheckboxStateOutlet:boolean;
  declare baseUrlValue:string;
  declare currentRoleIdsValue:unknown[];

  apply() {
    const panel = this.element as HTMLElement as SelectPanelElement;
    const selectedIds = panel.items
      .filter((item) => panel.isItemChecked(item))
      .map((item) => item.getAttribute('data-item-id'))
      .filter(Boolean);

    // For when all roles are deselected
    if (!selectedIds.length) {
      this.navigateTo(this.buildUrl([]));
      return;
    }

    if (selectedIds.slice().sort().join(',') === this.currentRoleIdsValue.slice().sort().join(',')) return;

    this.navigateTo(this.buildUrl(selectedIds as string[]));
  }

  private buildUrl(roleIds:string[]):string {
    const url = new URL(this.baseUrlValue, window.location.origin);
    roleIds.forEach((id) => url.searchParams.append('role_ids[]', id));
    return url.toString();
  }

  private navigateTo(url:string) {
    if (this.hasAdminWorkflowCheckboxStateOutlet) {
      this.adminWorkflowCheckboxStateOutlet.navigateTo(url);
    } else {
      Turbo.visit(url);
    }
  }
}
