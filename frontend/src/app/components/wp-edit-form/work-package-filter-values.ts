import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { QueryFilterInstanceResource } from 'core-app/modules/hal/resources/query-filter-instance-resource';
import { CurrentUserService } from "core-components/user/current-user.service";
import { HalResourceService } from 'core-app/modules/hal/services/hal-resource.service';
import { Injector } from '@angular/core';
import { AngularTrackingHelpers } from "core-components/angular/tracking-functions";
import { WorkPackageChangeset } from "core-components/wp-edit/work-package-changeset";
import compareByHrefOrString = AngularTrackingHelpers.compareByHrefOrString;
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";
import { FilterOperator } from "core-components/api/api-v3/api-v3-filter-builder";

export class WorkPackageFilterValues {

  @InjectField() currentUser:CurrentUserService;
  @InjectField() halResourceService:HalResourceService;

  handlers:Partial<Record<FilterOperator, (filter:QueryFilterInstanceResource) => void>> = {
    '=': this.applyFirstValue.bind(this),
    '!*': this.setToNull.bind(this)
  };

  constructor(public injector:Injector,
              private filters:QueryFilterInstanceResource[],
              private excluded:string[] = []) {

  }

  public applyDefaultsFromFilters(change:WorkPackageChangeset|Object) {
    _.each(this.filters, filter => {
      // Exclude filters specified in constructor
      if (this.excluded.indexOf(filter.id) !== -1) {
        return;
      }

      // Look for a handler with the filter's operator
      const operator = filter.operator.id as FilterOperator;
      const handler = this.handlers[operator];

      // Apply the filter if there is any
      handler?.call(this, change, filter);
    });
  }

  /**
   * Apply a positive value from a '=' [value] filter
   *
   * @param filter A positive '=' filter with at least one value
   * @private
   */
  private applyFirstValue(change:WorkPackageChangeset|{[id:string]:any}, filter:QueryFilterInstanceResource):void {
    // Avoid setting a value if current value is in filter list
    // and more than one value selected
    if (this.filterAlreadyApplied(change, filter)) {
      return;
    }

    // Select the first value
    const value = filter.values[0];

    // Avoid empty values
    if (value) {
      const attributeName = this.mapFilterToAttribute(filter);
      this.setValueFor(change, attributeName, value);
    }
  }

  /**
   * Set a value no null for a none type filter (!*)
   *
   * @param filter A none '!*' filter
   * @private
   */
  private setToNull(change:WorkPackageChangeset|{[id:string]:any}, filter:QueryFilterInstanceResource):void {
    const attributeName = this.mapFilterToAttribute(filter);

    this.setValue(change, attributeName,{ href: null });
  }

  private setValueFor(change:WorkPackageChangeset|Object, field:string, value:string|HalResource) {
    const newValue = this.findSpecialValue(value, field) || value;

    if (newValue) {
      this.setValue(change, field, newValue);
    }
  }

  private setValue(change:WorkPackageChangeset|{[id:string]:any}, field:string, value:any) {
    if (change instanceof WorkPackageChangeset) {
      change.setValue(field, value);
    } else {
      change[field] = value;
    }
  }

  /**
   * Returns special values for which no allowed values exist (e.g., parent ID in embedded queries)
   * @param {string | HalResource} value
   * @param {string} field
   */
  private findSpecialValue(value:string|HalResource, field:string):string|HalResource|undefined {
    if (field === 'parent') {
      return value;
    }

    if (value instanceof HalResource && value.$href === '/api/v3/users/me' && this.currentUser.isLoggedIn) {
      return this.halResourceService.fromSelfLink(`/api/v3/users/${this.currentUser.userId}`);
    }

    return undefined;
  }

  /**
   * Avoid applying filter values when
   *  - more than one filter value selected
   *  - changeset already matches one of the selected values
   * @param filter
   */
  private filterAlreadyApplied(change:WorkPackageChangeset|{[id:string]:any}, filter:any):boolean {
    // Only applicable if more than one selected
    if (filter.values.length <= 1) {
      return false;
    }

    const current = change instanceof WorkPackageChangeset ? change.projectedResource[filter.id] : change[filter.id];

    for (let i = 0; i < filter.values.length; i++) {
      if (compareByHrefOrString(current, filter.values[i])) {
        return true;
      }
    }

    return false;
  }

  /**
   * Some filter ids need to be mapped to a different attribute name
   * in order to be processed correctly.
   *
   * @param filter The filter to map
   * @returns An attribute name string to set
   * @private
   */
  private mapFilterToAttribute(filter:any):string {
    if (filter.id === 'onlySubproject') {
      return 'project';
    }

    // Default to returning the filter id
    return filter.id;
  }
}
