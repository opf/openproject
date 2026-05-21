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
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

export default class CreateDialogController extends Controller<HTMLFormElement> {
  private turboRequests:TurboRequestsService;

  static values = {
    refreshUrl: String,
    dialogUrlTemplate: String,
    refreshUrlTemplate: String,
  };

  declare refreshUrlValue:string;
  declare dialogUrlTemplateValue:string;
  declare refreshUrlTemplateValue:string;

  async connect() {
    const context = await window.OpenProject.getPluginContext();
    this.turboRequests = context.services.turboRequests;
  }

  refreshForm() {
    void this.turboRequests.submitForm(
      this.element,
      null,
      this.refreshUrlValue,
    );
  }

  updateProject() {
    const projectField = this.element.querySelector<HTMLInputElement>('[name="work_package[project_id]"]');
    const projectId = projectField?.value;
    if (!projectId) return;

    this.element.action = this.dialogUrlTemplateValue.replace(':id', projectId);
    this.refreshUrlValue = this.refreshUrlTemplateValue.replace(':id', projectId);

    this.refreshForm();
  }
}
