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

import * as Turbo from '@hotwired/turbo';
import { Controller } from '@hotwired/stimulus';

export default class IndexController extends Controller {
  static values = {
    journalStreamsUrl: String,
    sorting: String,
    pollingIntervalInMs: Number,
  };

  declare journalStreamsUrlValue:string;
  declare sortingValue:string;
  declare lastUpdateTimestamp:string;
  declare intervallId:number;
  declare pollingIntervalInMsValue:number;

  connect() {
    this.lastUpdateTimestamp = new Date().toISOString();
    this.handleWorkPackageUpdate = this.handleWorkPackageUpdate.bind(this);
    document.addEventListener('work-package-updated', this.handleWorkPackageUpdate);

    if (window.location.hash.includes('#activity-')) {
      this.scrollToActivity();
    } else if (this.sortingValue === 'asc') {
      this.scrollToBottom();
    }

    this.intervallId = this.pollForUpdates();
  }

  disconnect() {
    document.removeEventListener('work-package-updated', this.handleWorkPackageUpdate);
    window.clearInterval(this.intervallId);
  }

  scrollToActivity() {
    const activityId = window.location.hash.replace('#activity-', '');
    const activityElement = document.getElementById(`activity-${activityId}`);
    if (activityElement) {
      activityElement.scrollIntoView({ behavior: 'smooth' });
    }
  }

  scrollToBottom():void {
    // copied from frontend/src/app/features/work-packages/components/work-package-comment/work-package-comment.component.ts
    const scrollableContainer = jQuery(this.element).scrollParent()[0];
    if (scrollableContainer) {
      setTimeout(() => {
        scrollableContainer.scrollTop = scrollableContainer.scrollHeight;
      }, 400);
    }
  }

  async handleWorkPackageUpdate(event:Event) {
    setTimeout(() => {
      this.updateActivitiesList();
    }, 2000); // TODO: wait dynamically for persisted change before updating the activities list
  }

  async updateActivitiesList() {
    const url = new URL(this.journalStreamsUrlValue);
    url.searchParams.append('last_update_timestamp', this.lastUpdateTimestamp);

    const response = await fetch(
      url,
      {
        method: 'GET',
        headers: {
          'X-CSRF-Token': (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement).content,
          Accept: 'text/vnd.turbo-stream.html',
        },
        credentials: 'same-origin',
      },
    );

    if (response.ok) {
      const text = await response.text();
      Turbo.renderStreamMessage(text);
      this.lastUpdateTimestamp = new Date().toISOString();
    }
  }

  pollForUpdates() {
    // protypical implementation of polling for updates in order to evaluate if we want to have this feature
    return window.setInterval(() => {
      this.updateActivitiesList();
    }, this.pollingIntervalInMsValue);
  }
}
