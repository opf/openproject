import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import {
  collapsedRowClass,
  rowGroupClassName,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/grouped-classes.constants';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { States } from 'core-app/core/states/states.service';
import { GroupObject } from 'core-app/features/hal/resources/wp-collection-resource';
import { WorkPackageTable } from '../../../wp-fast-table';
import { tableRowClassName } from '../../rows/single-row-builder';
import { RowsBuilder } from '../rows-builder';
import { GroupHeaderBuilder } from './group-header-builder';
import { GroupedRenderPass } from './grouped-render-pass';
import { groupedRowClassName, groupIdentifier } from './grouped-rows-helpers';

export class GroupedRowsBuilder extends RowsBuilder {
  // Injections
  @InjectField() private readonly querySpace:IsolatedQuerySpace;

  @InjectField() public states:States;

  @InjectField() public wpTableColumns:WorkPackageViewColumnsService;

  @InjectField() public I18n:I18nService;

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

    jQuery(this.workPackageTable.tableAndTimelineContainer)
      .find(`.${rowGroupClassName}`)
      .each((i:number, oldRow:Element) => {
        const groupIndex = jQuery(oldRow).data('groupIndex');
        const group = groups[groupIndex];

        // Refresh the group header
        const newRow = builder.buildGroupRow(group, this.workPackageTable.colspan);

        if (oldRow.parentNode) {
          oldRow.parentNode.replaceChild(newRow, oldRow);
        }

        // Set expansion state of contained rows
        const affected = jQuery(this.workPackageTable.tableAndTimelineContainer)
          .find(`.${groupedRowClassName(groupIndex)}`);
        affected.toggleClass(collapsedRowClass, !!group.collapsed);

        // Update the hidden section of the rendered state
        affected.filter(`.${tableRowClassName}`).each((i, el) => {
          // Get the index of this row
          const index = jQuery(el).index();

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
