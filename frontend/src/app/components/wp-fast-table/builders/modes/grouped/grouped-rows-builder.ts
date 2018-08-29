import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {States} from '../../../../states.service';
import {WorkPackageTableColumnsService} from '../../../state/wp-table-columns.service';
import {WorkPackageTable} from '../../../wp-fast-table';
import {tableRowClassName} from '../../rows/single-row-builder';
import {RowsBuilder} from '../rows-builder';
import {GroupHeaderBuilder} from './group-header-builder';
import {GroupedRenderPass} from './grouped-render-pass';
import {groupedRowClassName, groupIdentifier} from './grouped-rows-helpers';
import {GroupObject} from 'core-app/modules/hal/resources/wp-collection-resource';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {
  collapsedRowClass,
  rowGroupClassName
} from "core-components/wp-fast-table/builders/modes/grouped/grouped-classes.constants";

export class GroupedRowsBuilder extends RowsBuilder {

  // Injections
  private readonly tableState = this.injector.get(TableState);
  public states:States = this.injector.get(States);
  public wpTableColumns:WorkPackageTableColumnsService = this.injector.get(WorkPackageTableColumnsService);
  public I18n:I18nService = this.injector.get(I18nService);

  private headerBuilder:GroupHeaderBuilder;

  constructor(public readonly injector:Injector, workPackageTable:WorkPackageTable) {
    super(injector, workPackageTable);
    this.headerBuilder = new GroupHeaderBuilder(this.injector);
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
    return this.tableState.groups.value || [];
  }

  /**
   * Returns the reference to the last table.collapesedGroups state value
   */
  public get collapsedGroups() {
    return this.tableState.collapsedGroups.value || {};
  }

  public get colspan() {
    return this.wpTableColumns.columnCount + 1;
  }

  public buildRows() {
    return new GroupedRenderPass(
      this.injector,
      this.workPackageTable,
      this.getGroupData(),
      this.headerBuilder,
      this.colspan
    ).render();
  }

  /**
   * Refresh the group expansion state
   */
  public refreshExpansionState() {
    const groups = this.getGroupData();
    const colspan = this.wpTableColumns.columnCount + 1;
    const rendered = this.tableState.rendered.value!;

    jQuery(this.workPackageTable.container)
      .find(`.${rowGroupClassName}`)
      .each((i:number, oldRow:Element) => {
      let groupIndex = jQuery(oldRow).data('groupIndex');
      let group = groups[groupIndex];

      // Refresh the group header
      let newRow = this.headerBuilder.buildGroupRow(group, colspan);

      if (oldRow.parentNode) {
        oldRow.parentNode.replaceChild(newRow, oldRow);
      }

      // Set expansion state of contained rows
      const affected = jQuery(`.${groupedRowClassName(groupIndex)}`);
      affected.toggleClass(collapsedRowClass, !!group.collapsed);

      // Update the hidden section of the rendered state
      affected.filter(`.${tableRowClassName}`).each((i, el) => {
        // Get the index of this row
        const index = jQuery(el).index();

        // Update the hidden state
        rendered[index].hidden = !!group.collapsed;
      });
    });

    this.tableState.rendered.putValue(rendered, 'Updated hidden state of rows after group change.');
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
