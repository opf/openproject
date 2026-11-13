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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectorRef, Component, DestroyRef, EventEmitter, HostBinding, Injector, Input, OnChanges, OnInit, Output, ViewEncapsulation, inject, viewChild,
} from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { filter } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  compareByHref,
} from 'core-app/shared/helpers/angular/tracking-functions';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { QueryOperatorResource } from 'core-app/features/hal/resources/query-operator-resource';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[query-filter]',
  styleUrls: ['./query-filter.component.sass'],
  templateUrl: './query-filter.component.html',
  encapsulation: ViewEncapsulation.None,
  standalone: false,
})
export class QueryFilterComponent implements OnChanges, OnInit {
  readonly wpTableFilters = inject(WorkPackageViewFiltersService);
  readonly wpTableBaseline = inject(WorkPackageViewBaselineService);
  readonly schemaCache = inject(SchemaCacheService);
  readonly I18n = inject(I18nService);
  readonly currentProject = inject(CurrentProjectService);

  private readonly cdRef = inject(ChangeDetectorRef);
  private readonly destroyRef = inject(DestroyRef);
  private readonly valueEditor = viewChild('valueEditor', { read: Injector });

  @HostBinding('class.op-query-filter') className = true;

  @Input() public shouldFocus = false;

  @Input() public filter:QueryFilterInstanceResource;

  @Output() public filterChanged = new EventEmitter<void>();

  @Output() public deactivateFilter = new EventEmitter<QueryFilterInstanceResource>();

  public availableOperators:QueryOperatorResource[];

  public eeShowBanners = false;

  public baselineIncompatibleFilter = false;

  public compareByHref = compareByHref;

  public text = {
    open_filter: this.I18n.t('js.filter.description.text_open_filter'),
    close_filter: this.I18n.t('js.filter.description.text_close_filter'),
    label_filter_add: this.I18n.t('js.work_packages.label_filter_add'),
    upsell_for_more: this.I18n.t('js.filter.upsell_for_more'),
    upsell_link: this.I18n.t('js.filter.upsell_link'),
    button_delete: this.I18n.t('js.button_delete'),
    incompatible_filter: this.I18n.t('js.work_packages.filters.baseline_incompatible'),
  };

  public onFilterUpdated(filter:QueryFilterInstanceResource) {
    this.filter = filter;
    this.markFilterForCheck();
    this.filterChanged.emit();
  }

  public removeThisFilter() {
    this.deactivateFilter.emit(this.filter);
  }

  public get valueType():string|undefined {
    if (this.filter.currentSchema?.values) {
      return this.filter.currentSchema.values.type;
    }

    return undefined;
  }

  public get showValuesInput():boolean {
    return !!this.filter.currentSchema?.isValueRequired() && this.valueType !== '[1]Boolean';
  }

  ngOnChanges():void {
    this.refreshFilterDetails();
  }

  ngOnInit():void {
    this.wpTableFilters.live$()
      .pipe(
        filter((filters) => filters.includes(this.filter)),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe(() => {
        this.refreshFilterDetails();
        this.markFilterForCheck();
      });
  }

  private refreshFilterDetails():void {
    this.availableOperators = this.schemaCache.of(this.filter).availableOperators as QueryOperatorResource[];
    this.baselineIncompatibleFilter = this.wpTableBaseline.isActive() && this.wpTableBaseline.isIncompatibleFilter(this.filter.id);
  }

  private markFilterForCheck():void {
    // Editors can keep the same filter instance when the operator or values change.
    const changeDetector = this.valueEditor()?.get(ChangeDetectorRef) ?? this.cdRef;
    changeDetector.markForCheck();
  }
}
