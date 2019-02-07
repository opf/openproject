import {
  Component,
  Injector,
  OnInit,
} from '@angular/core';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageTableFiltersService} from "core-components/wp-fast-table/state/wp-table-filters.service";
import {QueryFilterResource} from "core-app/modules/hal/resources/query-filter-resource";
import {QueryOperatorResource} from "core-app/modules/hal/resources/query-operator-resource";
import {QueryFilterInstanceResource} from "core-app/modules/hal/resources/query-filter-instance-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

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
    please_select: this.I18n.t('js.placeholders.selection'),
    first_part:    this.I18n.t('js.work_packages.table_configuration.relation_filters.first_part'),
    second_part:   this.I18n.t('js.work_packages.table_configuration.relation_filters.second_part'),
    parent:        this.I18n.t('js.types.attribute_groups.filter_types.parent'),
    precedes:      this.I18n.t('js.types.attribute_groups.filter_types.precedes'),
    follows:       this.I18n.t('js.types.attribute_groups.filter_types.follows'),
    relates:     this.I18n.t('js.types.attribute_groups.filter_types.relates'),
    duplicates:    this.I18n.t('js.types.attribute_groups.filter_types.duplicates'),
    duplicated:  this.I18n.t('js.types.attribute_groups.filter_types.duplicated'),
    blocks:        this.I18n.t('js.types.attribute_groups.filter_types.blocks'),
    blocked:     this.I18n.t('js.types.attribute_groups.filter_types.blocked'),
    requires:      this.I18n.t('js.types.attribute_groups.filter_types.requires'),
    required:    this.I18n.t('js.types.attribute_groups.filter_types.required'),
    partof:        this.I18n.t('js.types.attribute_groups.filter_types.partof'),
    includes:      this.I18n.t('js.types.attribute_groups.filter_types.includes')
  };

  constructor(readonly injector:Injector,
              readonly I18n:I18nService,
              readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly ConfigurationService:ConfigurationService) {
  }

  ngOnInit() {
    let self:WpTableConfigurationRelationSelectorComponent = this;

    this.wpTableFilters
      .onReady()
      .then(() => {
        self.availableRelationFilters = self.relationFiltersOf(self.wpTableFilters.currentState.availableFilters) as QueryFilterResource[];
        self.setSelectedRelationFilter();
      });
  }

  private setSelectedRelationFilter():void {
    let currentRelationFilters:QueryFilterInstanceResource[] = this.relationFiltersOf(this.wpTableFilters.currentState.current) as QueryFilterInstanceResource[];
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
    let filtersToRemove:QueryFilterInstanceResource[] = this.relationFiltersOf(this.wpTableFilters.currentState.current) as QueryFilterInstanceResource[];
    _.each(filtersToRemove, (filter) => this.wpTableFilters.currentState.remove(filter));
  }

  private relationFiltersOf(filters:QueryFilterResource[]|QueryFilterInstanceResource[]):QueryFilterResource[]|QueryFilterInstanceResource[] {
    return _.filter(filters, (filter:QueryFilterResource|QueryFilterInstanceResource) => _.includes(this.relationFilterIds, filter.id));
  }

  private addFilterToCurrentState(filter:QueryFilterResource):void {
    let addedFilter = this.wpTableFilters.currentState.add(filter);
    let operator:QueryOperatorResource = this.getOperatorForId(addedFilter, '=');
    addedFilter.operator = operator;
    addedFilter.values = [{href: '/api/v3/work_packages/{id}'}] as HalResource[];
  }

  private getOperatorForId(filter:QueryFilterResource, id:string):QueryOperatorResource {
    return _.find(filter.schema.availableOperators, { 'id': id}) as QueryOperatorResource;
  }

  public compareRelationFilters(f1:undefined|QueryFilterResource, f2:undefined|QueryFilterResource):boolean {
    return f1 && f2 ? f1.id === f2.id : f1 === f2;
  }
}
