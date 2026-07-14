import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { Injector } from '@angular/core';
import { compareByHrefOrString } from 'core-app/shared/helpers/angular/tracking-functions';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

export class WorkPackageFilterValues {
  @LazyInject() currentUser:CurrentUserService;

  @LazyInject() halResourceService:HalResourceService;

  @LazyInject() currentProject:CurrentProjectService;

  handlers:Partial<Record<FilterOperator, (change:WorkPackageChangeset|Record<string, unknown>, filter:QueryFilterInstanceResource) => void>> = {
    '=': this.applyFirstValue.bind(this),
    '!*': this.setToNull.bind(this),
  };

  constructor(
    public injector:Injector,
    private filters:QueryFilterInstanceResource[],
    private excluded:string[] = [],
  ) {}

  applyDefaultsFromFilters(change:WorkPackageChangeset|Record<string, unknown>):void {
    this.filters.forEach((filter) => {
      // Exclude filters specified in constructor
      if (this.excluded.includes(filter.id)) {
        return;
      }
      const operator = filter.operator.id as FilterOperator;

      // Special case due to the introduction of the project include dropdown
      // If we are in a project, we want the create wp to be part of that project.
      // Only for embedded tables, there might be different filter values necessary.
      if (filter.id === 'project') {
        if (operator !== '=') return;

        const currentProjectId = this.currentProject.id;
        const projectFilter = filter.values.find((resource:HalResource|string) => {
          const href = (resource instanceof HalResource) ? resource.href : resource;
          const hrefParts = href?.split('/');
          return hrefParts?.[hrefParts.length - 1] === currentProjectId;
        });
        this.setValue(change, 'project', projectFilter || filter.values[0]);

        return;
      }

      // ID filters should never be taken over
      if (filter.id === 'id') {
        return;
      }

      // Look for a handler with the filter's operator
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
  private applyFirstValue(change:WorkPackageChangeset|Record<string, unknown>, filter:QueryFilterInstanceResource):void {
    const attributeName = this.mapFilterToAttribute(filter);

    // Avoid setting a value if current value is in filter list
    // and more than one value selected
    if (this.filterAlreadyApplied(change, filter, attributeName)) {
      return;
    }

    // Select the first value
    const value = filter.values[0];

    // Avoid empty values
    if (value) {
      this.setValueFor(change, attributeName, value);
    }
  }

  /**
   * Set a value no null for a none type filter (!*)
   *
   * @param change changeset or resource
   * @param filter A none '!*' filter
   * @private
   */
  private setToNull(change:WorkPackageChangeset|Record<string, unknown>, filter:QueryFilterInstanceResource):void {
    const attributeName = this.mapFilterToAttribute(filter);

    this.setValue(change, attributeName, this.isMultiValueAttribute(attributeName) ? [] : { href: null });
  }

  private setValueFor(change:WorkPackageChangeset|Record<string, unknown>, field:string, value:string|HalResource):void {
    const newValue = this.findSpecialValue(value, field) || value;

    if (newValue) {
      this.setValue(change, field, this.isMultiValueAttribute(field) ? [newValue] : newValue);
    }
  }

  private setValue(change:WorkPackageChangeset|Record<string, unknown>, field:string, value:unknown):void {
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

    if (value instanceof HalResource && value.href === '/api/v3/users/me' && this.currentUser.isLoggedIn) {
      return this.halResourceService.fromSelfLink(`/api/v3/users/${this.currentUser.userId}`);
    }

    return undefined;
  }

  /**
   * Avoid applying filter values when changeset already matches one of the selected values
   * @param filter
   */
  private filterAlreadyApplied(
    change:WorkPackageChangeset|Record<string, unknown>,
    filter:{ id:string, values:unknown[] },
    attributeName:string = filter.id,
  ):boolean {
    const value:unknown = change instanceof WorkPackageChangeset ? change.projectedResource[attributeName] : change[attributeName];
    const current = Array.isArray(value) ? value : [value];

    for (let i = 0; i < filter.values.length; i++) {
      for (let j = 0; j < current.length; j++) {
        if (compareByHrefOrString(current[j], filter.values[i])) {
          return true;
        }
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

    // Version filters write the multi-valued targetVersions attribute,
    // which replaces the deprecated single-valued version attribute.
    if (filter.id === 'version' || filter.id === 'targetVersion') {
      return 'targetVersions';
    }

    // Default to returning the filter id
    return filter.id;
  }

  private isMultiValueAttribute(attributeName:string):boolean {
    return attributeName === 'targetVersions';
  }
}
