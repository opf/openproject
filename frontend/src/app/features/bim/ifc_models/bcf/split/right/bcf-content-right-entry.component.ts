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

import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import {
  WorkPackageStatesInitializationService,
} from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { BcfViewService } from 'core-app/features/bim/ifc_models/pages/viewer/bcf-view.service';

/**
 * Entry component for the reactive BCF list shown in the content-bodyRight turbo frame
 * whenever no WP detail/create pane is open (see index.html.erb) - BcfSplitRightComponent
 * itself only renders that list when the current display mode is splitTable/splitCards.
 *
 * Bootstrapped as its own, independent Angular Elements island, entirely separate from
 * op-bcf-content-left's: it derives everything from the same URL as the left pane, so it
 * doesn't need to share query-space state with it, only load the same query independently -
 * the same pattern already used by the WP split-view/split-create entry components.
 */
@Component({
  selector: 'op-bcf-content-right-entry',
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  standalone: false,
  providers: [
    BcfViewService,
  ],
  template: '<op-bcf-content-right />',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BcfContentRightEntryComponent implements OnInit {
  private readonly wpListService = inject(WorkPackagesListService);
  private readonly wpStatesInitialization = inject(WorkPackageStatesInitializationService);
  private readonly currentProject = inject(CurrentProjectService);
  private readonly bcfView = inject(BcfViewService);

  ngOnInit():void {
    void this.wpListService
      .loadCurrentQueryFromParams(this.currentProject.identifier ?? undefined)
      .then((query) => {
        this.bcfView.initialize(query, query.results);
        this.wpStatesInitialization.initialize(query, query.results);
      });
  }
}
