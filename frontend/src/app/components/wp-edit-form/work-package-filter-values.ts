import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {FormResource} from 'core-app/modules/hal/resources/form-resource';
import {WorkPackageChangeset} from './work-package-changeset';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';

export class WorkPackageFilterValues {

  constructor(private changeset:WorkPackageChangeset,
              private filters:QueryFilterInstanceResource[],
              private excluded:string[] = []) {

  }

  public async applyDefaultsFromFilters() {
    return this.changeset.getForm().then(async (form) => {
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

  private async setAllowedValueFor(form:FormResource, field:string, value:string|HalResource) {
    return this.allowedValuesFor(form, field).then((allowedValues) => {
      let newValue;

      if ((value as HalResource)['$href']) {
        newValue = _.find(allowedValues,
          (entry:any) => entry.$href === (value as HalResource).$href);
      } else if (allowedValues) {
        newValue = _.find(allowedValues, (entry:any) => entry === value);
      } else {
        newValue = value;
      }

      if (newValue) {
        this.changeset.setValue(field, newValue);
        this.changeset.workPackage[field] = newValue;
      }
    });
  }

  private async allowedValuesFor(form:FormResource, field:string):Promise<HalResource[]> {
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
