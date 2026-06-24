import { Injector } from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { collapsedRowClass } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-classes.constants';
import { GroupSumsBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/group-sums-builder';
import { GroupObject } from 'core-app/features/hal/resources/wp-collection-resource';
import { WorkPackageTable } from '../../../wp-fast-table';
import { WorkPackageTableRow } from '../../../wp-table.interfaces';
import { SingleRowBuilder } from '../../rows/single-row-builder';
import { PlainRenderPass } from '../plain/plain-render-pass';
import {
  groupClassNameFor,
  GroupHeaderBuilder,
} from './group-header-builder';
import {
  groupByProperty,
  groupedRowClassName,
} from './grouped-rows-helpers';

export const groupRowClass = '-group-row';

export class GroupedRenderPass extends PlainRenderPass {
  private sumsBuilder = new GroupSumsBuilder(this.injector, this.workPackageTable);

  constructor(public readonly injector:Injector,
    public workPackageTable:WorkPackageTable,
    public groups:GroupObject[],
    public headerBuilder:GroupHeaderBuilder,
    public colspan:number,
  ) {
    super(injector, workPackageTable, new SingleRowBuilder(injector, workPackageTable));
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   */
  protected doRender() {
    let currentGroup:GroupObject|null = null;
    this.workPackageTable.originalRows.forEach((wpId:string) => {
      const row = this.workPackageTable.originalRowIndex[wpId];
      const nextGroup = this.matchingGroup(row.object);
      const groupsChanged = currentGroup !== nextGroup;

      // Render the sums row
      if (currentGroup && groupsChanged) {
        this.renderSumsRow(currentGroup);
      }

      // Render the next group row
      if (nextGroup && groupsChanged) {
        const groupClass = groupClassNameFor(nextGroup);
        const rowElement = this.headerBuilder.buildGroupRow(nextGroup, this.colspan);
        this.appendNonWorkPackageRow(rowElement, groupClass, [groupRowClass]);
        currentGroup = nextGroup;
      }

      row.group = currentGroup;
      this.buildSingleRow(row);
    });

    // Render the last sums row
    if (currentGroup) {
      this.renderSumsRow(currentGroup);
    }
  }

  /**
   * Find a matching group for the given work package.
   * The API sadly doesn't provide us with the information which group a WP belongs to.
   */
  private matchingGroup(workPackage:WorkPackageResource) {
    return this.groups.find((group:GroupObject) => {
      let property = workPackage[groupByProperty(group)] as unknown;
      // explicitly check for undefined as `false` (bool) is a valid value.
      if (property === undefined) {
        property = null;
      }

      // If the property is a multi-value
      // Compare the href's of all resources with the ones in valueLink
      if (Array.isArray(property)) {
        return this.matchesMultiValue(property as HalResource[], group);
      }

      /// / If it's a linked resource, compare the href,
      /// / which is an array of links the resource offers
      if (this.hasHref(property)) {
        return group._links.valueLink.some((l) => property.href === l.href);
      }

      // Otherwise, fall back to simple value comparison.
      const groupValue = group.value as unknown;
      let value = groupValue === '' ? null : groupValue;

      if (value && typeof value === 'string') {
        // For matching we have to remove the % sign which is shown when grouping after progress
        value = value.replace('%', '');
      }

      // Values provided by the API are always string
      // so avoid triple equal here
      return value == property;
    })!;
  }

  private hasHref(value:unknown):value is { href:string } {
    if (typeof value !== 'object' || value === null) {
      return false;
    }

    const href = (value as { href?:unknown }).href;
    return typeof href === 'string' && href.length > 0;
  }

  private matchesMultiValue(property:HalResource[], group:GroupObject) {
    // The API returns `group.href` as an object keyed by index rather than a
    // plain array, so normalise it via `Object.values` before comparing.
    const groupHrefs = Object.values(group.href);

    if (property.length !== groupHrefs.length) {
      return false;
    }

    // `property` may be a read-only observable array whose `map` returns a
    // read-only array (via `Symbol.species`), so build a plain array via
    // `Array.from` before sorting to avoid a "read-only" RangeError.
    const joinedOrderedHrefs = (objects:{ href:string|null }[]) => Array.from(objects, (object) => object.href).sort().join(', ');

    return joinedOrderedHrefs(property) === joinedOrderedHrefs(groupHrefs);
  }

  /**
   * Enhance a row from the rowBuilder with group information.
   */
  private buildSingleRow(row:WorkPackageTableRow):void {
    const { group } = row;

    if (!group) {
      console.warn("All rows should have a group, but this one doesn't %O", row);
    }

    let hidden = false;
    const additionalClasses:string[] = [];

    const [tr, _] = this.rowBuilder.buildEmpty(row.object);

    if (group) {
      additionalClasses.push(groupedRowClassName(group.index));
      hidden = !!group.collapsed;

      if (hidden) {
        additionalClasses.push(collapsedRowClass);
      }
    }

    row.element = tr;
    tr.classList.add(...additionalClasses);
    this.appendRow(row.object, tr, additionalClasses, hidden);
  }

  /**
   * Render the sums row for the current group
   */
  private renderSumsRow(group:GroupObject) {
    if (!group.sums) {
      return;
    }

    const groupClass = groupClassNameFor(group);
    const rowElement = this.sumsBuilder.buildSumsRow(group);
    this.appendNonWorkPackageRow(rowElement, groupClass);
  }
}
