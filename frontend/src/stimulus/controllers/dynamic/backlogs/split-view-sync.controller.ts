//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import type { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { useAngularServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';

// A split view open on a moved work package caches the lock_version it fetched
// on opening, so the next edit after a move would fail with a
// conflicting-modifications error. The server signals every successful move via
// a document event; this controller refreshes the moved work package in the
// Angular cache so the split view stays editable.
export default class SplitViewSyncController extends Controller {
  static services:ServiceKey[] = ['apiV3Service'];

  declare apiV3Service:ApiV3Service;

  initialize() {
    useAngularServices(this);
  }

  // Bound to the `op-dispatched:backlogs:work-package-moved` document event.
  // Refreshes a work package already in the cache. The most likely reason for this is that the
  // work package is or has been displayed in the split view. Refreshing prevents
  // the lock version becoming stale after move and also reflects the change to the sprint and
  // bucket property.
  // The method currently does not check if the work package is still open in the split view. If it
  // was ever opened, it will still be in the cache leading to a refresh request. The upside of this potentially
  // wasteful refresh is that when the work package is later on reopened in the split view, its information
  // is correct as well.
  onWorkPackageMoved(event:CustomEvent<{ work_package_id?:number; work_package_ids?:number[] }>):void {
    const detail = event.detail ?? {};
    const ids = detail.work_package_ids
      ?? (detail.work_package_id !== undefined ? [detail.work_package_id] : []);
    // apiV3Service is wired asynchronously via useAngularServices, so it may be absent
    // if the event somehow fires before the services resolve.
    if (ids.length === 0 || !this.apiV3Service) { return; }

    const { work_packages: workPackages } = this.apiV3Service;

    ids.forEach((rawId) => {
      const id = rawId.toString();
      if (workPackages.cache.state(id).hasValue()) {
        void workPackages.id(id).refresh();
      }
    });
  }
}
