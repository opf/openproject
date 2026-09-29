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

import { AfterViewInit, ChangeDetectionStrategy, Component, Input, inject } from '@angular/core';
import { Board } from 'core-app/features/boards/board/board';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { debounceTime, skip, take } from 'rxjs/operators';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { Observable } from 'rxjs';
import { BoardFiltersService } from 'core-app/features/boards/board/board-filter/board-filters.service';
import { BoardActionsRegistryService } from 'core-app/features/boards/board/board-actions/board-actions-registry.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import * as Turbo from '@hotwired/turbo';

@Component({
  selector: 'board-filter',
  templateUrl: './board-filter.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class BoardFilterComponent extends UntilDestroyedMixin implements AfterViewInit {
  private readonly currentProjectService = inject(CurrentProjectService);
  private readonly querySpace = inject(IsolatedQuerySpace);
  private readonly apiV3Service = inject(ApiV3Service);
  private readonly halResourceService = inject(HalResourceService);
  private readonly wpStatesInitialization = inject(WorkPackageStatesInitializationService);
  private readonly wpTableFilters = inject(WorkPackageViewFiltersService);
  private readonly urlParamsHelper = inject(UrlParamsHelperService);
  private readonly boardFilters = inject(BoardFiltersService);
  private readonly boardActionRegistry = inject(BoardActionsRegistryService);

  /** Current active */
  @Input() public board$:Observable<Board>;

  initialized = false;

  ngAfterViewInit():void {
    if (!this.board$) {
      return;
    }

    this.board$
      .pipe(take(1))
      .subscribe((board) => {
        // Initially load the form once to be able to render filters
        this.loadQueryForm();

        // Update checksum service whenever filters change
        this.updateChecksumOnFilterChanges();

        // Remove action attribute from filter service, under every
        // filter id the action filter may be rendered as
        if (board.isAction) {
          this.wpTableFilters.hidden.push(...this.boardActionRegistry.get(board.actionAttribute!).filterNames);
        }
      });
  }

  private updateChecksumOnFilterChanges() {
    this.wpTableFilters
      .live$()
      .pipe(
        this.untilDestroyed(),
        skip(1),
        debounceTime(250),
      )
      .subscribe(() => {
        const filters:QueryFilterInstanceResource[] = this.wpTableFilters.current;
        const filterHash = this.urlParamsHelper.buildV3GetFilters(filters);
        const query_props = JSON.stringify(filterHash);

        const url = new URL(window.location.href);
        if (query_props) {
          url.searchParams.set('query_props', query_props);
        } else {
          url.searchParams.delete('query_props');
        }
        Turbo.session.history.push(url);

        this.boardFilters.filters.putValue(filterHash);
      });
  }

  private loadQueryForm() {
    this
      .apiV3Service
      .queries
      .form
      .loadWithParams(
        { filters: JSON.stringify(this.boardFilters.current) },
        undefined,
        this.currentProjectService.id,
      )
      .subscribe(([form, query]) => {
        this.querySpace.query.putValue(query);
        this.wpStatesInitialization.updateStatesFromForm(query, form);
      });
  }
}
