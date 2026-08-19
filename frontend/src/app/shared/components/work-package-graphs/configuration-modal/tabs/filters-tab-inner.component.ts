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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { WpGraphConfigurationService } from 'core-app/shared/components/work-package-graphs/configuration/wp-graph-configuration.service';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { QuerySpacedTabComponent } from 'core-app/shared/components/work-package-graphs/configuration-modal/tabs/abstract-query-spaced-tab.component';
import { WorkPackageFiltersService } from 'core-app/features/work-packages/components/filters/wp-filters/wp-filters.service';

@Component({
  selector: 'op-filters-tab-inner',
  templateUrl: './filters-tab-inner.component.html',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WpGraphConfigurationFiltersTabInnerComponent extends QuerySpacedTabComponent implements TabComponent, OnInit {
  readonly I18n:I18nService;
  readonly wpTableFilters = inject(WorkPackageViewFiltersService);
  readonly wpFiltersService = inject(WorkPackageFiltersService);
  readonly wpStatesInitialization:WorkPackageStatesInitializationService;
  readonly wpGraphConfiguration:WpGraphConfigurationService;
  private cdRef = inject(ChangeDetectorRef);

  public filters:QueryFilterInstanceResource[] = [];

  public text = {
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),
  };

  constructor() {
    const I18n = inject(I18nService);
    const wpStatesInitialization = inject(WorkPackageStatesInitializationService);
    const wpGraphConfiguration = inject(WpGraphConfigurationService);

    super(I18n, wpStatesInitialization, wpGraphConfiguration);

    this.I18n = I18n;
    this.wpStatesInitialization = wpStatesInitialization;
    this.wpGraphConfiguration = wpGraphConfiguration;
  }

  ngOnInit() {
    void this.initializeQuerySpace()
      .then(() => {
        void this.wpTableFilters
          .onReady()
          .then(() => {
            this.filters = this.wpTableFilters.current;
            this.cdRef.markForCheck();
          });
      });
  }

  public onSave() {
    if (this.filters) {
      this.wpTableFilters.replaceIfComplete(this.filters);
      this.wpTableFilters.applyToQuery(this.wpGraphConfiguration.queries[0]);
    }
  }

  protected get query() {
    return this.wpGraphConfiguration.queries[0];
  }
}
