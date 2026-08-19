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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { WorkPackageCreateComponent } from 'core-app/features/work-packages/components/wp-new/wp-create.component';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';

@Component({
  selector: 'wp-new-split-view',
  templateUrl: './wp-new-split-view.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageNewSplitViewComponent extends WorkPackageCreateComponent {
  private readonly wpListService = inject(WorkPackagesListService);

  /**
   * Before creating the new WP form, load the current query (with its active filters)
   * into the isolated query space so that WorkPackageCreateService.defaultsFromFilters()
   * can pre-populate the form fields automatically — no manual filter mapping needed.
   */
  protected override async createdWorkPackage() {
    if (!this.routedFromAngular) {
      const params = new URLSearchParams(window.location.search);

      // Load the active query into the isolated query space so that
      // WorkPackageCreateService.defaultsFromFilters() can pre-populate filter-based fields.
      const queryId = params.get('query_id');
      const queryProps = params.get('query_props');
      if (queryId || queryProps) {
        await firstValueFrom(
          this.wpListService.fromQueryParams(
            { query_id: queryId ?? undefined, query_props: queryProps ?? undefined },
            this.currentProjectService.identifier ?? undefined,
          ),
        );
      }

      // Apply defaults passed via URL params (e.g. when dragging to create on the calendar/team planner).
      const startDate = params.get('startDate');
      const dueDate = params.get('dueDate');
      const ignoreNonWorkingDays = params.get('ignoreNonWorkingDays');
      const assigneeHref = params.get('assignee_href');
      const parentId = params.get('parent_id');
      if (startDate || dueDate || ignoreNonWorkingDays || assigneeHref || parentId) {
        const existingDefaults = this.stateParams?.defaults;
        this.stateParams = {
          ...this.stateParams,
          ...(parentId ? { parent_id: parentId } : {}),
          defaults: {
            _links: {},
            ...existingDefaults,
            ...(startDate ? { startDate } : {}),
            ...(dueDate ? { dueDate } : {}),
            ...(ignoreNonWorkingDays ? { ignoreNonWorkingDays: true } : {}),
            ...(assigneeHref ? {
              _links: {
                ...(existingDefaults?._links || {}),
                assignee: { href: assigneeHref },
              },
            } : {}),
          },
        };
      }
    }

    return super.createdWorkPackage();
  }

  public override cancelAndBack():void {
    if (this.routedFromAngular) {
      super.cancelAndBack();
      return;
    }

    this.wpCreate.cancelCreation();

    // Close the split panel by navigating to the base URL (strips /details/new),
    // replacing the history entry so back-navigation skips the create state.
    const basePath = window.location.pathname.replace(/\/details\/.*$/, '');
    Turbo.visit(basePath + window.location.search, { frame: 'content-bodyRight', action: 'replace' });
  }

  public override onSaved(params:{ savedResource:WorkPackageResource, isInitial:boolean }):void {
    if (this.routedFromAngular) {
      super.onSaved(params);
      return;
    }

    const { savedResource, isInitial } = params;
    this.editForm?.cancel(false);

    this.notificationService.showSave(savedResource, isInitial);
    window.OpenProject.pageState = 'submitted';

    // Open the newly created WP in the split panel.
    const basePath = window.location.pathname.replace(/\/details\/.*$/, '');
    Turbo.visit(`${basePath}/details/${savedResource.id}${window.location.search}`, {
      frame: 'content-bodyRight',
      action: 'advance',
    });
  }
}
