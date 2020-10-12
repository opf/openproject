import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {States} from '../../../../states.service';
import {WorkPackageTable} from '../../../wp-fast-table';
import {tableRowClassName} from '../../rows/single-row-builder';
import {RowsBuilder} from '../rows-builder';
import {GroupHeaderBuilder} from './group-header-builder';
import {GroupedRenderPass} from './grouped-render-pass';
import {groupedRowClassName, groupIdentifier} from './grouped-rows-helpers';
import {GroupObject} from 'core-app/modules/hal/resources/wp-collection-resource';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {
  collapsedRowClass,
  rowGroupClassName
} from "core-components/wp-fast-table/builders/modes/grouped/grouped-classes.constants";
import {WorkPackageViewColumnsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

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
   * The hierarchy builder is only applicable if the hierachy mode is active
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

  public get colspan() {
    // Columns + manual sorting column + settings column
    return this.wpTableColumns.columnCount + 2;
  }

  public buildRows() {
    const builder = new GroupHeaderBuilder(this.injector);
    return new GroupedRenderPass(
      this.injector,
      this.workPackageTable,
      this.getGroupData(),
      builder,
      this.colspan
    ).render();
  }

  /**
   * Refresh the group expansion state
   */
  public refreshExpansionState() {
    const groups = this.getGroupData();
    const colspan = this.wpTableColumns.columnCount + 1;
    const rendered = this.querySpace.tableRendered.value!;
    const builder = new GroupHeaderBuilder(this.injector);

    jQuery(this.workPackageTable.tableAndTimelineContainer)
      .find(`.${rowGroupClassName}`)
      .each((i:number, oldRow:Element) => {
        let groupIndex = jQuery(oldRow).data('groupIndex');
        let group = groups[groupIndex];

        // Refresh the group header
        let newRow = builder.buildGroupRow(group, colspan);

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
