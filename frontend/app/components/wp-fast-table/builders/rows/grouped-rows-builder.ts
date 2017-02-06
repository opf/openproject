import {RowsBuilder} from './rows-builder';
import {States} from '../../../states.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {groupedRowClassName} from '../../helpers/wp-table-row-helpers';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {SingleRowBuilder} from './single-row-builder';
import {WorkPackageResource} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {GroupObject} from '../../wp-table.interfaces';

export const rowGroupClassName = 'wp-table--group-header';
export const collapsedRowClass = '-collapsed';

export class GroupedRowsBuilder extends RowsBuilder {
  // Injections
  public states:States;
  public wpTableColumns:WorkPackageTableColumnsService;
  public I18n:op.I18n;

  private text:any;

  constructor() {
    super();
    injectorBridge(this);

    this.text = {
      collapse: this.I18n.t('js.label_collapse'),
      expand: this.I18n.t('js.label_expand'),
    };
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   * @param table
   */
  public buildRows(table:WorkPackageTable) {
    let groupBy = table.metaData.groupBy;
    let groups = this.getGroupData(groupBy, table.metaData.groups);

    // Remember the colspan for the group rows from the current column count
    // and add one for the details link.
    let colspan = this.wpTableColumns.columnCount + 1;
    let tbodyContent = document.createDocumentFragment();

    let currentGroup = null;
    table.rows.forEach((wpId:string) => {
      let row = table.rowIndex[wpId];
      let nextGroup = this.matchingGroup(row.object, groups, groupBy);

      if (currentGroup !== nextGroup) {
        tbodyContent.appendChild(this.buildGroupRow(nextGroup, colspan));
        currentGroup = nextGroup;
      }

      row.group = currentGroup;
      let tr = this.buildSingleRow(row);
      tbodyContent.appendChild(tr);
    });

    return tbodyContent;
  }

  /**
   * Find a matching group for the given work package.
   * The API sadly doesn't provide us with the information which group a WP belongs to.
   */
  private matchingGroup(workPackage:WorkPackageResource, groups:GroupObject[], groupBy:string) {
    return _.find(groups, (group) => {
      // If its a linked resource, compare the href.
      if (group.href) {
        return workPackage.$source._links[groupBy].href === group.href;
      }

      // Otherwise, fall back to simple value comparison.
      let value = group.value === '' ? null : group.value;
      return value === workPackage[groupBy];
    });
  }

  /**
   * Refresh the group expansion state
   */
  public refreshExpansionState(table) {
    let groups = this.getGroupData(table.metaData.groupBy, table.metaData.groups);
    let colspan = this.wpTableColumns.columnCount + 1;

    jQuery(`.${rowGroupClassName}`).each((i:number, oldRow:HTMLElement) => {
      let groupIndex = jQuery(oldRow).data('groupIndex');
      let group = groups[groupIndex];

      // Set expansion state of contained rows
      jQuery(`.${groupedRowClassName(groupIndex)}`).toggleClass(collapsedRowClass, group.collapsed);

      // Refresh the group header
      let newRow = this.buildGroupRow(group, colspan);
      oldRow.parentNode.replaceChild(newRow, oldRow);
    });
  }

  /**
   * Augment the given groups with the current collapsed state data.
   */
  public getGroupData(groupBy:string, groups:GroupObject[]) {
    let collapsedState = this.states.table.collapsedGroups.getCurrentValue() || {};

    return groups.map((group:GroupObject, index:number) => {
      group.index = index;
      if (group._links && group._links.valueLink) {
        group.href = group._links.valueLink.href;
      }
      group.identifier = this.groupIdentifier(groupBy, group);
      group.collapsed = collapsedState[group.identifier] === true;
      return group;
    });
  }

  /**
   * Redraw a single row, while maintain its group state.
   */
  public buildEmptyRow(row, table):HTMLElement {
    return this.buildSingleRow(row);
  }

  public groupIdentifier(groupBy, group:GroupObject) {
    return `${groupBy}-${group.href || group.value || 'nullValue'}`;
  }

  /**
   * Enhance a row from the rowBuilder with group information.
   */
  private buildSingleRow(row) {
    let tr = this.rowBuilder.buildEmpty(row.object);
    tr.classList.add(groupedRowClassName(row.group.index));

    if (row.group.collapsed) {
      tr.classList.add(collapsedRowClass);
    }

    row.element = tr;
    return tr;
  }

  /**
   * Build group header row
   */
  private buildGroupRow(group:GroupObject, colspan:number) {
    let row = document.createElement('tr');
    let togglerIconClass, text;

    if (group.collapsed) {
      text = this.text.expand;
      togglerIconClass = 'icon-plus';
    } else {
      text = this.text.collapse;
      togglerIconClass = 'icon-minus2';
    }

    row.classList.add(rowGroupClassName);
    row.id = `wp-table-rowgroup-${group.index}`;
    row.dataset['groupIndex'] = group.index.toString();
    row.dataset['groupIdentifier'] = group.identifier;
    row.innerHTML = `
      <td colspan="${colspan}">
        <div class="expander icon-context ${togglerIconClass}">
          <span class="hidden-for-sighted">${_.escape(text)}</span>
        </div>
        <div class="group--value">
          ${_.escape(this.groupName(group))}
          <span class="count">
            (${group.count})
          </span>
        </div>
      </td>
    `;

    return row;
  }

  private groupName(group:GroupObject) {
    let value = group.value;
    if (value === null) {
      return '-';
    } else {
      return value;
    }
  }
}


GroupedRowsBuilder.$inject = ['wpTableColumns', 'states', 'I18n'];
