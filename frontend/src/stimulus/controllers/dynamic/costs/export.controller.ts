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
import * as Turbo from '@hotwired/turbo';
import { HttpErrorResponse } from '@angular/common/http';
import { useAngularServices, type PickedServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

export default class ExportController extends Controller<HTMLLinkElement> {
  static services:ServiceKey[] = ['notifications'];

  static values = {
    jobStatusDialogUrl: String,
  };

  declare services:Promise<PickedServices<'notifications'>>;

  declare jobStatusDialogUrlValue:string;

  initialize() {
    useAngularServices(this);
  }

  jobModalUrl(job_id:string):string {
    return this.jobStatusDialogUrlValue.replace('_job_uuid_', job_id);
  }

  async showJobModal(job_id:string) {
    const response = await fetch(this.jobModalUrl(job_id), {
      method: 'GET',
      headers: { Accept: 'text/vnd.turbo-stream.html' },
    });
    if (response.ok) {
      Turbo.renderStreamMessage(await response.text());
    } else {
      throw new Error(response.statusText || 'Invalid response from server');
    }
  }

  async requestExport(exportURL:string):Promise<string> {
    const response = await fetch(exportURL, {
      method: 'GET',
      headers: { Accept: 'application/json' },
      credentials: 'same-origin',
    });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    const result = await response.json() as { job_id:string };
    if (!result.job_id) {
      throw new Error('Invalid response from server');
    }
    return result.job_id;
  }

  get href() {
    return this.element.href;
  }

  download(evt:CustomEvent) {
    evt.preventDefault(); // Don't follow the href
    this.requestExport(this.href)
      .then((job_id) => this.showJobModal(job_id))
      .catch((error:HttpErrorResponse) => { void this.handleError(error); });
  }

  private async handleError(error:HttpErrorResponse) {
    const { notifications } = await this.services;
    notifications.addError(error);
  }
}
