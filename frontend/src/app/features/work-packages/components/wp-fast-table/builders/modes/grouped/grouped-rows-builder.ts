import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import {
  collapsedRowClass,
  rowGroupClassName,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-classes.constants';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { States } from 'core-app/core/states/states.service';
import { GroupObject } from 'core-app/features/hal/resources/wp-collection-resource';
import { WorkPackageTable } from '../../../wp-fast-table';
import { tableRowClassName } from '../../rows/single-row-builder';
import { RowsBuilder } from '../rows-builder';
import { GroupHeaderBuilder } from './group-header-builder';
import { GroupedRenderPass } from './grouped-render-pass';
import { groupedRowClassName, groupIdentifier } from './grouped-rows-helpers';
import { getNodeIndex } from 'core-app/shared/helpers/dom-helpers';

export class GroupedRowsBuilder extends RowsBuilder {
  // Injections
  @LazyInject() private readonly querySpace:IsolatedQuerySpace;

  @LazyInject() public states:States;

  @LazyInject() public wpTableColumns:WorkPackageViewColumnsService;

  @LazyInject() public I18n:I18nService;

  constructor(public readonly injector:Injector, workPackageTable:WorkPackageTable) {
    super(injector, workPackageTable);
  }

  /**
   * The hierarchy builder is only applicable if the hierarchy mode is active
   */
  public isApplicable(table:WorkPackageTable) {
    return !_.isEmpty(this.groups);
  }

  /**
   * Returns the reference to the last table.groups state value
   */
  public get groups() {
    return this.querySpace.groups.value || [];
  }

  /**
   * Returns the reference to the last table.collapesedGroups state value
   */
  public get collapsedGroups() {
    return this.querySpace.collapsedGroups.value || {};
  }

  public buildRows() {
    const builder = new GroupHeaderBuilder(this.injector);
    return new GroupedRenderPass(
      this.injector,
      this.workPackageTable,
      this.getGroupData(),
      builder,
      this.workPackageTable.colspan,
    ).render();
  }

  /**
   * Refresh the group expansion state
   */
  public refreshExpansionState() {
    const groups = this.getGroupData();
    const rendered = this.querySpace.tableRendered.value!;
    const builder = new GroupHeaderBuilder(this.injector);

    this.workPackageTable.tableAndTimelineContainer
      .querySelectorAll<HTMLTableRowElement>(`.${rowGroupClassName}`)
      .forEach((oldRow) => {
        const groupIndex = parseInt(oldRow.dataset.groupIndex || '', 10);
        const group = groups[groupIndex];

        // Refresh the group header
        const newRow = builder.buildGroupRow(group, this.workPackageTable.colspan);

        if (oldRow.parentNode) {
          oldRow.parentNode.replaceChild(newRow, oldRow);
        }

        // Set expansion state of contained rows
        const affected = Array.from(this.workPackageTable.tableAndTimelineContainer
          .querySelectorAll(`.${groupedRowClassName(groupIndex)}`));

        affected.forEach((el) => el.classList.toggle(collapsedRowClass, !!group.collapsed));

        // Update the hidden section of the rendered state
        affected
          .filter((el) => el.matches(`.${tableRowClassName}`))
          .forEach((el) => {
          // Get the index of this row
          const index = getNodeIndex(el);

          // Update the hidden state
          rendered[index].hidden = !!group.collapsed;
        });
      });

    this.querySpace.tableRendered.putValue(rendered, 'Updated hidden state of rows after group change.');
  }

  /**
   * Augment the given groups with the current collapsed state data.
   */
  private getGroupData() {
    return this.groups.map((group:GroupObject, index:number) => {
      group.index = index;
      if (group._links && group._links.valueLink) {
        group.href = group._links.valueLink;
      }
      group.identifier = groupIdentifier(group);
      group.collapsed = this.collapsedGroups[group.identifier];
      return group;
    });
  }
}
