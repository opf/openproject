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

import { ReplaySubject } from 'rxjs';
import { Injectable, inject } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';

/** Matches the full-view "show" page: /work_packages/:id/:tab (project-scoped or global). */
const showTabPattern = /\/work_packages\/[^/]+\/([^/?]+)$/;

/** Matches the split-view "details" pane: <any list base>/details/:id/:tab. */
const detailsTabPattern = /\/details\/[^/]+\/([^/?]+)$/;

@Injectable({ providedIn: 'root' })
export class KeepTabService {
  protected pathHelper = inject(PathHelperService);
  protected currentProject = inject(CurrentProjectService);
  protected urlParams = inject(UrlParamsService);

  protected currentTab = 'overview';

  protected subject = new ReplaySubject<Record<string, string>>(1);

  constructor() {
    this.updateTabs();
    this.urlParams.changed$.subscribe(() => this.updateTabs());
  }

  public get observable() {
    return this.subject;
  }

  /**
   * Return the last active tab.
   */
  public get lastActiveTab():string {
    if (this.currentShowTabFromUrl) {
      return this.currentShowTab;
    }

    return this.currentDetailsTab;
  }

  public goCurrentShowState(workPackageId:string):void {
    window.location.href = this.currentShowHref(workPackageId);
  }

  public currentShowHref(workPackageId:string):string {
    const projectIdentifier = this.currentProject.identifier;
    return this.pathHelper.genericWorkPackagePath(projectIdentifier, workPackageId, this.currentShowTab) + window.location.search;
  }

  public isDetailsState(stateName:string):boolean {
    return !!stateName && stateName.includes('.details');
  }

  public get currentShowTab():string {
    // Show view doesn't have overview
    // use activity instead
    if (this.currentTab === 'overview') {
      return 'activity';
    }

    return this.currentTab;
  }

  public get currentDetailsTab():string {
    return this.currentTab;
  }

  protected notify() {
    // Notify when updated
    this.subject.next({
      active: this.lastActiveTab,
      show: this.currentShowTab,
      details: this.currentDetailsTab,
    });
  }

  private get currentShowTabFromUrl():string|null {
    return this.urlParams.pathMatching(showTabPattern);
  }

  private get currentDetailsTabFromUrl():string|null {
    return this.urlParams.pathMatching(detailsTabPattern);
  }

  public updateTabs():void {
    const showTab = this.currentShowTabFromUrl;
    if (showTab) {
      // Ignore the switch from show#activity to details#activity
      // and show details#overview instead
      this.currentTab = showTab === 'activity' ? 'overview' : showTab;
      this.notify();
      return;
    }

    const detailsTab = this.currentDetailsTabFromUrl;
    if (detailsTab) {
      this.currentTab = detailsTab;
      this.notify();
    }
  }
}
