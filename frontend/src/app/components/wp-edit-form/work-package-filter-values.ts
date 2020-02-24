import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {CurrentUserService} from "core-components/user/current-user.service";
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {Injector} from '@angular/core';
import {AngularTrackingHelpers} from "core-components/angular/tracking-functions";
import {WorkPackageChangeset} from "core-components/wp-edit/work-package-changeset";
import compareByHrefOrString = AngularTrackingHelpers.compareByHrefOrString;
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class WorkPackageFilterValues {

  @InjectField() currentUser:CurrentUserService;
  @InjectField() halResourceService:HalResourceService;

  constructor(public injector:Injector,
              private change:WorkPackageChangeset,
              private filters:QueryFilterInstanceResource[],
              private excluded:string[] = []) {

  }

  public applyDefaultsFromFilters() {
    _.each(this.filters, filter => {
      // Ignore any filters except =
      if (filter.operator.id !== '=') {
        return;
      }

      // Exclude filters specified in constructor
      if (this.excluded.indexOf(filter.id) !== -1) {
        return;
      }

      // Avoid setting a value if current value is in filter list
      // and more than one value selected
      if (this.filterAlreadyApplied(filter)) {
        return;
      }

      // Select the first value
      let value = filter.values[0];

      // Avoid empty values
      if (value) {
        this.setValueFor(filter.id, value);
      }
    });
  }

  private setValueFor(field:string, value:string|HalResource) {
    let newValue = this.findSpecialValue(value, field) || value;

    if (newValue) {
      this.change.projectedResource[field] = newValue;
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
  private filterAlreadyApplied(filter:any):boolean {
    // Only applicable if more than one selected
    if (filter.values.length <= 1) {
      return false;
    }

    const current = this.change.projectedResource[filter.id];

    for (let i = 0; i < filter.values.length; i++) {
      if (compareByHrefOrString(current, filter.values[i])) {
        return true;
      }
    }

    return false;
  }
}
