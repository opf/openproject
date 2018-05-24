import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {FormResource} from 'core-app/modules/hal/resources/form-resource';
import {WorkPackageChangeset} from './work-package-changeset';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {all} from "@uirouter/core";

export class WorkPackageFilterValues {

  constructor(private changeset:WorkPackageChangeset,
              private filters:QueryFilterInstanceResource[],
              private excluded:string[] = []) {

  }

  public applyDefaultsFromFilters() {
    return this.changeset.getForm().then((form) => {
      const promises:Promise<any>[] = [];
      angular.forEach(this.filters, filter => {
        // Ignore any filters except =
        if (filter.operator.id !== '=') {
          return;
        }

        // Exclude filters specified in constructor
        if (this.excluded.indexOf(filter.id) !== -1) {
          return;
        }

        // Select the first value
        var value = filter.values[0];

        // Avoid empty values
        if (!value) {
          return;
        }

        promises.push(this.setAllowedValueFor(form, filter.id, value));
      });

      return Promise.all(promises);
    });
  }

  private setAllowedValueFor(form:FormResource, field:string, value:string|HalResource) {
    return this.allowedValuesFor(form, field).then((allowedValues) => {
      let newValue = this.findSpecialValue(value, field) || this.findAllowedValue(value, allowedValues);

      if (newValue) {
        this.changeset.setValue(field, newValue);
        this.changeset.workPackage[field] = newValue;
      }
    });
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

    return undefined;
  }

  private findAllowedValue(value:string|HalResource, allowedValues:HalResource[]) {
    if (value instanceof HalResource && !!value.$href) {
      return _.find(allowedValues,
        (entry:any) => entry.$href === value.$href);
    } else if (allowedValues) {
      return _.find(allowedValues, (entry:any) => entry === value);
    } else {
      return value;
    }
  }

  private allowedValuesFor(form:FormResource, field:string):Promise<HalResource[]> {
    const fieldSchema = form.schema[field];

    return new Promise<HalResource[]>(resolve => {
      if (!fieldSchema) {
        resolve([]);
      } else if (fieldSchema.allowedValues && fieldSchema.allowedValues['$load']) {
        let allowedValues = fieldSchema.allowedValues;

        return allowedValues.$load().then((loadedValues:CollectionResource) => {
          resolve(loadedValues.elements);
        });
      } else {
        resolve(fieldSchema.allowedValues);
      }
    });
  }
}
