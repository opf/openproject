import {RowsBuilder} from '../rows-builder';
import {States} from '../../../../states.service';
import {WorkPackageTableColumnsService} from '../../../state/wp-table-columns.service';
import {WorkPackageTable} from '../../../wp-fast-table';
import {injectorBridge} from '../../../../angular/angular-injector-bridge.functions';
import {GroupObject} from '../../../../api/api-v3/hal-resources/wp-collection-resource.service';
import {GroupedRenderPass} from './grouped-render-pass';
import {groupedRowClassName, groupIdentifier} from './grouped-rows-helpers';
import {GroupHeaderBuilder} from './group-header-builder';
import {tableRowClassName} from '../../rows/single-row-builder';

export const rowGroupClassName = 'wp-table--group-header';
export const collapsedRowClass = '-collapsed';

export class GroupedRowsBuilder extends RowsBuilder {
  // Injections
  public states:States;
  public wpTableColumns:WorkPackageTableColumnsService;
  public I18n:op.I18n;

  private headerBuilder:GroupHeaderBuilder;

  constructor(workPackageTable:WorkPackageTable) {
    super(workPackageTable);
    injectorBridge(this);

    this.headerBuilder = new GroupHeaderBuilder();
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
    return this.states.table.groups.value || [];
  }

  /**
   * Returns the reference to the last table.collapesedGroups state value
   */
  public get collapsedGroups() {
    return this.states.table.collapsedGroups.value || {};
  }

  public get colspan() {
    return this.wpTableColumns.columnCount + 1;
  }

  public buildRows() {
    return new GroupedRenderPass(
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
    const rendered = this.states.table.rendered.value!;

    jQuery(`.${rowGroupClassName}`).each((i:number, oldRow:HTMLElement) => {
      let groupIndex = jQuery(oldRow).data('groupIndex');
      let group = groups[groupIndex];

      // Refresh the group header
      let newRow = this.headerBuilder.buildGroupRow(group, colspan);

      if (oldRow.parentNode) {
        oldRow.parentNode.replaceChild(newRow, oldRow);
      }

      // Set expansion state of contained rows
      const affected = jQuery(`.${groupedRowClassName(groupIndex)}`);
      affected.toggleClass(collapsedRowClass, group.collapsed);

      // Update the hidden section of the rendered state
      affected.filter(`.${tableRowClassName}`).each((i, el) => {
        // Get the index of this row
        const index = jQuery(el).index();

        // Update the hidden state
        rendered[index].hidden = !!group.collapsed;
      });
    });

    this.states.table.rendered.putValue(rendered, 'Updated hidden state of rows after group change.');
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
      group.collapsed = this.collapsedGroups[group.identifier] === true;
      return group;
    });
  }
}

GroupedRowsBuilder.$inject = ['wpTableColumns', 'states', 'I18n'];
