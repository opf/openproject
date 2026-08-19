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

import { StateService } from '@uirouter/core';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

export const uiStateLinkClass = '__ui-state-link';
export const checkedClassName = '-checked';
export const pressedClassName = '-pressed';

export class UiStateLinkBuilder {
  constructor(
    public readonly $state:StateService,
    public readonly keepTab:KeepTabService,
    public readonly currentProject:CurrentProjectService,
    public readonly pathHelper:PathHelperService,
  ) {
  }

  public linkToDetails(workPackageId:string, title:string, content:string, routingId?:string) {
    return this.build(workPackageId, 'split', title, content, routingId);
  }

  public linkToShow(workPackageId:string, title:string, content:string, routingId?:string) {
    return this.build(workPackageId, 'show', title, content, routingId);
  }

  /**
   * Build an anchor element that serves two purposes:
   *
   * - **href** uses `routingId` (semantic, e.g. "PROJ-7") so the URL bar
   *   and "open in new tab" show human-readable identifiers.
   * - **data-work-package-id** always uses the numeric `workPackageId` (PK)
   *   because the selection, focus, and hover systems are keyed by PK.
   *
   * Click handlers (WorkPackageStateLinksHandler) read the data attribute
   * and call preventDefault() — the href is never followed during normal
   * in-table clicks. It only matters for right-click / open-in-new-tab.
   */
  private build(workPackageId:string, state:'show'|'split', title:string, content:string, routingId?:string) {
    const a = document.createElement('a');
    const idForHref = routingId ?? workPackageId;
    let href:string;

    if (state === 'show') {
      const projectIdentifier = this.currentProject.identifier;
      href = this.pathHelper.genericWorkPackagePath(projectIdentifier, idForHref, this.keepTab.currentShowTab) + window.location.search;
    } else {
      // Param key must match the route declaration in split-view-routes.template.ts
      // (`:tabIdentifier`). A mismatch makes $state.href return null, which
      // surfaces as the literal string "null" in the rendered href.
      const tabIdentifier = this.keepTab.currentDetailsTab;
      href = this.$state.href(
        'work-packages.partitioned.list.details.tabs',
        {
          workPackageId: idForHref,
          tabIdentifier,
        },
      );
    }

    a.href = href;
    a.classList.add(uiStateLinkClass);
    a.dataset.workPackageId = workPackageId;
    a.dataset.wpState = state;

    a.setAttribute('title', title);
    a.textContent = content;

    return a;
  }
}
