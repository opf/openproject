import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {FormResource} from 'core-app/modules/hal/resources/form-resource';
import {WorkPackageChangeset} from './work-package-changeset';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {CurrentUserService} from "core-components/user/current-user.service";
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {Injector} from '@angular/core';

export class WorkPackageFilterValues {

  private currentUser:CurrentUserService = this.injector.get(CurrentUserService);
  private halResourceService:HalResourceService = this.injector.get(HalResourceService);

  constructor(private injector:Injector,
              private changeset:WorkPackageChangeset,
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
      this.changeset.setValue(field, newValue);
      this.changeset.workPackage[field] = newValue;
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
}
