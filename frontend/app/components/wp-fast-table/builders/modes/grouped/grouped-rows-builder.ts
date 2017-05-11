import {RowsBuilder} from "../rows-builder";
import {States} from "../../../../states.service";
import {WorkPackageTableColumnsService} from "../../../state/wp-table-columns.service";
import {WorkPackageTable} from "../../../wp-fast-table";
import {injectorBridge} from "../../../../angular/angular-injector-bridge.functions";
import {GroupObject} from "../../../../api/api-v3/hal-resources/wp-collection-resource.service";
import {WorkPackageResource} from "../../../../api/api-v3/hal-resources/work-package-resource.service";
import {HalResource} from "../../../../api/api-v3/hal-resources/hal-resource.service";
import {groupedRowClassName} from "../../../helpers/wp-table-row-helpers";
import {WorkPackageTableRow} from "../../../wp-table.interfaces";
export const rowGroupClassName = 'wp-table--group-header';
export const collapsedRowClass = '-collapsed';

export class GroupedRowsBuilder extends RowsBuilder {
  // Injections
  public states:States;
  public wpTableColumns:WorkPackageTableColumnsService;
  public I18n:op.I18n;

  private text:any;

  constructor(workPackageTable: WorkPackageTable) {
    super(workPackageTable);
    injectorBridge(this);

    this.text = {
      collapse: this.I18n.t('js.label_collapse'),
      expand: this.I18n.t('js.label_expand'),
    };
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

  /**
   * Rebuild the entire grouped tbody from the given table
   * @param table
   */
  public internalBuildRows(table:WorkPackageTable):[DocumentFragment, DocumentFragment] {
    const groups = this.getGroupData();

    // Remember the colspan for the group rows from the current column count
    // and add one for the details link.
    let colspan = this.wpTableColumns.columnCount + 1;

    let tableBody = document.createDocumentFragment();
    let timelineBody = document.createDocumentFragment();

    let currentGroup:GroupObject|null = null;
    table.rows.forEach((wpId:string) => {
      let row = table.rowIndex[wpId];
      let nextGroup = this.matchingGroup(row.object, groups);

      if (nextGroup && currentGroup !== nextGroup) {
        let rowElement = this.buildGroupRow(nextGroup, colspan);
        this.appendRow(null, rowElement, tableBody, timelineBody);
        currentGroup = nextGroup;
      }

      row.group = currentGroup;
      let tr = this.buildSingleRow(row);
      this.appendRow(row.object, tr, tableBody, timelineBody);
    });

    return [tableBody, timelineBody];
  }

  /**
   * Find a matching group for the given work package.
   * The API sadly doesn't provide us with the information which group a WP belongs to.
   */
  private matchingGroup(workPackage:WorkPackageResource, groups:GroupObject[]) {
    return _.find(groups, (group:GroupObject) => {
      let property = workPackage[this.groupByProperty(group)]
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
      return value === property;
    }) as GroupObject;
  }

  /**
   * Refresh the group expansion state
   */
  public refreshExpansionState() {
    const groups = this.getGroupData();
    const colspan = this.wpTableColumns.columnCount + 1;

    jQuery(`.${rowGroupClassName}`).each((i:number, oldRow:HTMLElement) => {
      let groupIndex = jQuery(oldRow).data('groupIndex');
      let group = groups[groupIndex];

      // Set expansion state of contained rows
      jQuery(`.${groupedRowClassName(groupIndex)}`).toggleClass(collapsedRowClass, group.collapsed);

      // Refresh the group header
      let newRow = this.buildGroupRow(group, colspan);

      if (oldRow.parentNode) {
        oldRow.parentNode.replaceChild(newRow, oldRow);
      }
    });
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
      group.identifier = this.groupIdentifier(group);
      group.collapsed = this.collapsedGroups[group.identifier] === true;
      return group;
    });
  }

  private matchesMultiValue(property:HalResource[], group:GroupObject) {
    if (property.length !== group.href.length) {
      return false;
    }

    let joinedOrderedHrefs = (objects:any[]) => {
      return _.map(objects, object => object.href).sort().join(', ')
    }

    return _.isEqualWith(property,
                         group.href,
                         (a, b) => joinedOrderedHrefs(a) === joinedOrderedHrefs(b));
  }

  /**
   * Redraw a single row, while maintain its group state.
   */
  public buildEmptyRow(row:WorkPackageTableRow, table:WorkPackageTable):HTMLElement {
    return this.buildSingleRow(row);
  }

  public groupIdentifier(group:GroupObject) {
    return `${this.groupByProperty(group)}-${group.value || 'nullValue'}`;
  }

  /**
   * Enhance a row from the rowBuilder with group information.
   */
  private buildSingleRow(row:WorkPackageTableRow):HTMLElement {
    // Do not re-render rows before their grouping data
    // is completed after the first try
    if (!row.group) {
      return row.element as HTMLElement;
    }

    const group = row.group as GroupObject;
    let tr = this.rowBuilder.buildEmpty(row.object);
    tr.classList.add(groupedRowClassName(group.index as number));

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
    row.dataset['groupIndex'] = (group.index as number).toString();
    row.dataset['groupIdentifier'] = group.identifier as string;
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

  private groupByProperty(group:GroupObject):string {
    return group._links!.groupBy.href.split('/').pop()!;
  }
}

GroupedRowsBuilder.$inject = ['wpTableColumns', 'states', 'I18n'];
