import {
  Component,
  Injector,
  OnInit,
} from '@angular/core';
import { ConfigurationService } from 'core-app/modules/common/config/configuration.service';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { WorkPackageViewFiltersService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import { QueryFilterResource } from "core-app/modules/hal/resources/query-filter-resource";
import { QueryOperatorResource } from "core-app/modules/hal/resources/query-operator-resource";
import { QueryFilterInstanceResource } from "core-app/modules/hal/resources/query-filter-instance-resource";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";

@Component({
  templateUrl: './wp-table-configuration-relation-selector.html',
  selector: 'wp-table-configuration-relation-selector'
})
export class WpTableConfigurationRelationSelectorComponent implements OnInit  {
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
    'required'
  ];

  public availableRelationFilters:QueryFilterResource[] = [];
  public selectedRelationFilter:QueryFilterResource|undefined = undefined;

  public text = {
    filter_work_packages_by_relation_type: this.I18n.t('js.work_packages.table_configuration.relation_filters.filter_work_packages_by_relation_type'),
    please_select: this.I18n.t('js.placeholders.selection'),
    // We need to inverse the translation strings, as the filters's are named the other way around than what
    // a user knows from the relations tab:
    parent:        this.I18n.t('js.relation_labels.children'),
    precedes:      this.I18n.t('js.relation_labels.follows'),
    follows:       this.I18n.t('js.relation_labels.precedes'),
    relates:     this.I18n.t('js.relation_labels.relates'),
    duplicates:    this.I18n.t('js.relation_labels.duplicated'),
    duplicated:  this.I18n.t('js.relation_labels.duplicates'),
    blocks:        this.I18n.t('js.relation_labels.blocked'),
    blocked:     this.I18n.t('js.relation_labels.blocks'),
    requires:      this.I18n.t('js.relation_labels.required'),
    required:    this.I18n.t('js.relation_labels.requires'),
    partof:        this.I18n.t('js.relation_labels.includes'),
    includes:      this.I18n.t('js.relation_labels.partof')
  };

  constructor(readonly injector:Injector,
              readonly I18n:I18nService,
              readonly wpTableFilters:WorkPackageViewFiltersService,
              readonly ConfigurationService:ConfigurationService,
              readonly schemaCache:SchemaCacheService) {
  }

  ngOnInit() {
    const self:WpTableConfigurationRelationSelectorComponent = this;

    this.wpTableFilters
      .onReady()
      .then(() => {
        self.availableRelationFilters = self.relationFiltersOf(self.wpTableFilters.availableFilters) as QueryFilterResource[];
        self.setSelectedRelationFilter();
      });
  }

  private setSelectedRelationFilter():void {
    const currentRelationFilters:QueryFilterInstanceResource[] = this.relationFiltersOf(this.wpTableFilters.current) as QueryFilterInstanceResource[];
    if (currentRelationFilters.length > 0) {
      this.selectedRelationFilter = _.find(this.availableRelationFilters, { id: currentRelationFilters[0].id }) as QueryFilterResource;
    } else {
      this.selectedRelationFilter = this.availableRelationFilters[0];
    }
    this.onRelationFilterSelected();
  }

  public onRelationFilterSelected() {
    if (this.selectedRelationFilter) {
      this.removeRelationFiltersFromCurrentState();
      this.addFilterToCurrentState(this.selectedRelationFilter as QueryFilterResource);
    }
  }

  private removeRelationFiltersFromCurrentState() {
    const filtersToRemove = this.relationFiltersOf(this.wpTableFilters.current) as QueryFilterInstanceResource[];
    this.wpTableFilters.remove(...filtersToRemove);
  }

  private relationFiltersOf(filters:QueryFilterResource[]|QueryFilterInstanceResource[]):QueryFilterResource[]|QueryFilterInstanceResource[] {
    return _.filter(filters, (filter:QueryFilterResource|QueryFilterInstanceResource) => _.includes(this.relationFilterIds, filter.id));
  }

  private addFilterToCurrentState(filter:QueryFilterResource):void {
    const newFilter = this.wpTableFilters.instantiate(filter);
    const operator:QueryOperatorResource = this.getOperatorForId(newFilter, '=');
    newFilter.operator = operator;
    newFilter.values = [{ href: '/api/v3/work_packages/{id}' }] as HalResource[];

    this.wpTableFilters.add(newFilter);
  }

  private getOperatorForId(filter:QueryFilterResource, id:string):QueryOperatorResource {
    return _.find(this.schemaCache.of(filter).availableOperators, { 'id': id }) as QueryOperatorResource;
  }

  public compareRelationFilters(f1:undefined|QueryFilterResource, f2:undefined|QueryFilterResource):boolean {
    return f1 && f2 ? f1.id === f2.id : f1 === f2;
  }
}
