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

import { ChangeDetectionStrategy, Component, Injector, OnInit, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  TabComponent,
} from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import {
  WorkPackageFiltersService,
} from 'core-app/features/work-packages/components/filters/wp-filters/wp-filters.service';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';

@Component({
  templateUrl: './filters-tab.component.html',
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-table-config-filters-tab',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WpTableConfigurationFiltersTabComponent implements TabComponent, OnInit {
  readonly injector = inject(Injector);
  readonly I18n = inject(I18nService);
  readonly wpTableFilters = inject(WorkPackageViewFiltersService);
  readonly wpFiltersService = inject(WorkPackageFiltersService);

  public filters:QueryFilterInstanceResource[] = [];

  public eeShowBanners = false;

  public text = {
    columnsLabel: this.I18n.t('js.label_columns'),
    selectedColumns: this.I18n.t('js.description_selected_columns'),
    multiSelectLabel: this.I18n.t('js.work_packages.label_column_multiselect'),
  };

  ngOnInit() {
    this.wpTableFilters
      .onReady()
      .then(() => this.filters = this.wpTableFilters.current);

    this.wpTableFilters.changes$().subscribe((filters) => {
      this.filters = this.wpTableFilters.current;
    });
  }

  public onSave() {
    if (this.filters) {
      this.wpTableFilters.replaceIfComplete(this.filters);
    }
  }
}
