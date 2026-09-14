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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, OnInit, inject } from '@angular/core';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';
import { QueryOperatorResource } from 'core-app/features/hal/resources/query-operator-resource';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';

@Component({
  templateUrl: './wp-table-configuration-relation-selector.html',
  selector: 'wp-table-configuration-relation-selector',
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WpTableConfigurationRelationSelectorComponent implements OnInit {
  readonly injector = inject(Injector);
  readonly I18n = inject(I18nService);
  readonly wpTableFilters = inject(WorkPackageViewFiltersService);
  readonly ConfigurationService = inject(ConfigurationService);
  readonly schemaCache = inject(SchemaCacheService);
  readonly cdRef = inject(ChangeDetectorRef);

  private relationFilterIds:string[] = [
    'parent',
    'precedes',
    'follows',
    'relates',
    'duplicates',
    'duplicated',
    'blocks',
    'blocked',
    'partof',
    'includes',
    'requires',
    'required',
  ];

  public availableRelationFilters:QueryFilterResource[] = [];

  public selectedRelationFilter:QueryFilterResource|undefined = undefined;

  public text = {
    filter_work_packages_by_relation_type: this.I18n.t('js.work_packages.table_configuration.relation_filters.filter_work_packages_by_relation_type'),
    please_select: this.I18n.t('js.placeholders.selection'),
    // We need to inverse the translation strings, as the filters's are named the other way around than what
    // a user knows from the relations tab:
    parent: this.I18n.t('js.relation_labels.children'),
    precedes: this.I18n.t('js.relation_labels.follows'),
    follows: this.I18n.t('js.relation_labels.precedes'),
    relates: this.I18n.t('js.relation_labels.relates'),
    duplicates: this.I18n.t('js.relation_labels.duplicated'),
    duplicated: this.I18n.t('js.relation_labels.duplicates'),
    blocks: this.I18n.t('js.relation_labels.blocked'),
    blocked: this.I18n.t('js.relation_labels.blocks'),
    requires: this.I18n.t('js.relation_labels.required'),
    required: this.I18n.t('js.relation_labels.requires'),
    partof: this.I18n.t('js.relation_labels.includes'),
    includes: this.I18n.t('js.relation_labels.partof'),
  };

  ngOnInit() {
    void this.initializeRelationFilters();
  }

  private async initializeRelationFilters():Promise<void> {
    await this.wpTableFilters.onReady();
    this.availableRelationFilters = this.relationFiltersOf(this.wpTableFilters.availableFilters);
    this.setSelectedRelationFilter();
    this.cdRef.markForCheck();
  }

  private setSelectedRelationFilter():void {
    const currentRelationFilters:QueryFilterInstanceResource[] = this.relationFiltersOf(this.wpTableFilters.current) as QueryFilterInstanceResource[];
    if (currentRelationFilters.length > 0) {
      this.selectedRelationFilter = this.availableRelationFilters.find((relationFilter) => relationFilter.id === currentRelationFilters[0].id)!;
    } else {
      this.selectedRelationFilter = this.availableRelationFilters[0];
    }
    this.onRelationFilterSelected();
  }

  public onRelationFilterSelected() {
    if (this.selectedRelationFilter) {
      this.removeRelationFiltersFromCurrentState();
      this.addFilterToCurrentState(this.selectedRelationFilter);
    }
  }

  private removeRelationFiltersFromCurrentState() {
    const filtersToRemove = this.relationFiltersOf(this.wpTableFilters.current) as QueryFilterInstanceResource[];
    this.wpTableFilters.remove(...filtersToRemove);
  }

  private relationFiltersOf(filters:QueryFilterResource[]|QueryFilterInstanceResource[]):QueryFilterResource[]|QueryFilterInstanceResource[] {
    return filters.filter((filter:QueryFilterResource|QueryFilterInstanceResource) => this.relationFilterIds.includes(filter.id));
  }

  private addFilterToCurrentState(filter:QueryFilterResource):void {
    const newFilter = this.wpTableFilters.instantiate(filter);
    const operator:QueryOperatorResource = this.getOperatorForId(newFilter, '=');
    newFilter.operator = operator;
    newFilter.values = [{ href: '/api/v3/work_packages/{id}' }] as HalResource[];

    this.wpTableFilters.add(newFilter);
  }

  private getOperatorForId(filter:QueryFilterResource, id:string):QueryOperatorResource {
    return (this.schemaCache.of(filter).availableOperators as QueryOperatorResource[]).find((operator:QueryOperatorResource) => operator.id === id)!;
  }

  public compareRelationFilters(f1:undefined|QueryFilterResource, f2:undefined|QueryFilterResource):boolean {
    return f1 && f2 ? f1.id === f2.id : f1 === f2;
  }
}
