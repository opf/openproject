import {Injectable} from "@angular/core";
import {QueryFormResource} from "core-app/modules/hal/resources/query-form-resource";
import {QueryFilterInstanceSchemaResource} from "core-app/modules/hal/resources/query-filter-instance-schema-resource";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {QueryFilterInstanceResource} from "core-app/modules/hal/resources/query-filter-instance-resource";

@Injectable()
export class QueryFiltersService {

  /**
   * Get the matching schema of the filter resource
   * from the schema
   */
  public getFilterSchema(filter:QueryFilterInstanceResource, form:QueryFormResource):QueryFilterInstanceSchemaResource|undefined {
    const available = form.$embedded.schema.filtersSchemas.elements;
    return _.find(available, schema => schema.allowedFilterValue.href === filter.filter.href);
  }

  /**
   * Map all filters of the query with the appropriate schema.
   * @param query
   * @param form
   */
  public mapSchemasIntoFilters(query:QueryResource, form:QueryFormResource) {
    query.filters.forEach(filter => {
      filter.schema = this.getFilterSchema(filter, form)!;
    });
  }
}
