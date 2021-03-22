import { Injector } from '@angular/core';
import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { WorkPackageTable } from '../../../wp-fast-table';
import { WorkPackageTableRow } from '../../../wp-table.interfaces';
import { SingleRowBuilder } from '../../rows/single-row-builder';
import { PlainRenderPass } from '../plain/plain-render-pass';
import { groupClassNameFor, GroupHeaderBuilder } from './group-header-builder';
import { groupByProperty, groupedRowClassName } from './grouped-rows-helpers';
import { GroupObject } from 'core-app/modules/hal/resources/wp-collection-resource';
import { collapsedRowClass } from "core-components/wp-fast-table/builders/modes/grouped/grouped-classes.constants";
import { GroupSumsBuilder } from "core-components/wp-fast-table/builders/modes/grouped/group-sums-builder";

export const groupRowClass = '-group-row';

export class GroupedRenderPass extends PlainRenderPass {

  private sumsBuilder = new GroupSumsBuilder(this.injector, this.workPackageTable);

  constructor(public readonly injector:Injector,
              public workPackageTable:WorkPackageTable,
              public groups:GroupObject[],
              public headerBuilder:GroupHeaderBuilder,
              public colspan:number) {

    super(injector, workPackageTable, new SingleRowBuilder(injector, workPackageTable));
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   */
  protected doRender() {
    let currentGroup:GroupObject | null = null;
    const length = this.workPackageTable.originalRows.length;
    this.workPackageTable.originalRows.forEach((wpId:string, index:number) => {
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
    return _.find(this.groups, (group:GroupObject) => {
      let property = workPackage[groupByProperty(group)];
      // explicitly check for undefined as `false` (bool) is a valid value.
      if (property === undefined) {
        property = null;
      }

      // If the property is a multi-value
      // Compare the href's of all resources with the ones in valueLink
      if (_.isArray(property)) {
        return this.matchesMultiValue(property as HalResource[], group);
      }

      //// If its a linked resource, compare the href,
      //// which is an array of links the resource offers
      if (property && property.$href) {
        return !!_.find(group._links.valueLink, (l:any):any => property.$href === l.href);
      }

      // Otherwise, fall back to simple value comparison.
      let value = group.value === '' ? null : group.value;

      if (value) {
        // For matching we have to remove the % sign which is shown when grouping after progress
        value = value.replace('%', '');
      }

      // Values provided by the API are always string
      // so avoid triple equal here
      // tslint:disable-next-line
      return value == property;
    }) as GroupObject;
  }

  private matchesMultiValue(property:HalResource[], group:GroupObject) {
    if (property.length !== group.href.length) {
      return false;
    }

    const joinedOrderedHrefs = (objects:any[]) => {
      return _.map(objects, object => object.href).sort().join(', ');
    };

    return _.isEqualWith(
      property,
      group.href,
      (a, b) => joinedOrderedHrefs(a) === joinedOrderedHrefs(b)
    );
  }

  /**
   * Enhance a row from the rowBuilder with group information.
   */
  private buildSingleRow(row:WorkPackageTableRow):void {
    const group = row.group;

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
