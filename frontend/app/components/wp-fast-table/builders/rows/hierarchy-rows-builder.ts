import {UiStateLinkBuilder} from '../ui-state-link-builder';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {HalResource} from '../../../api/api-v3/hal-resources/hal-resource.service';
import {WorkPackageTableRow} from '../../wp-table.interfaces';
import {PlainRowsBuilder} from './plain-rows-builder';
import {RowsBuilder} from './rows-builder';
import {States} from '../../../states.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {SingleRowBuilder} from './single-row-builder';

export const indicatorCollapsedClass = '-hierarchy-collapsed';
export const hierarchyCellClassName = 'wp-table--hierarchy-span';

export class HierarchyRowsBuilder extends PlainRowsBuilder {
  // Injections
  public states:States;
  public wpTableColumns:WorkPackageTableColumnsService;
  public I18n:op.I18n;

  public uiStateBuilder = new UiStateLinkBuilder();

  // The group expansion state
  constructor() {
    super();
    injectorBridge(this);
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   * @param table
   */
  public buildRows(table:WorkPackageTable):DocumentFragment {
    // Remember all additional rows drawn for hierarchy
    const additional:{[workPackageId:string]: WorkPackageResourceInterface} = {};

    const tbodyContent = document.createDocumentFragment();

    table.rows.forEach((wpId:string) => {
      let row:WorkPackageTableRow = table.rowIndex[wpId];

      // If we have ancestors
      if (row.object.ancestors.length) {
        this.buildWithHierarchy(tbodyContent, row, additional);
      } else {
        let tr = this.buildEmptyRow(row);
        row.element = tr;
        tbodyContent.appendChild(tr);
      }

      additional[row.object.id] = row.object;
    });

    return tbodyContent;
  }

  public get colspan():number {
    return this.wpTableColumns.columnCount + 1;
  }

  public buildEmptyRow(row:WorkPackageTableRow, table?:WorkPackageTable) {
    let element = this.rowBuilder.buildEmpty(row.object);
    let level = row.object.ancestors.length;
    let hierarchyIndicator = this.buildHierarchyIndicator(row.object, level);

    if (level > 0) {
      element.classList.add(...row.object.ancestors.map((ancestor) => `__hierarchy-group-${ancestor.id}`));
    }

    element.classList.add(`__hierarchy-root-${row.object.id}`);
    jQuery(element).find('td.subject').prepend(hierarchyIndicator);
    return element;
  }

  /**
   * Build the hierarchy indicator at the given indentation level.
   */
  private buildHierarchyIndicator(workPackage:WorkPackageResourceInterface, level:number, collapsed:boolean = false):HTMLElement {
      const hierarchyIndicator = document.createElement('span');
      hierarchyIndicator.classList.add(hierarchyCellClassName);
      hierarchyIndicator.style.width = 10 + (10 * level) + 'px';
      hierarchyIndicator.style.paddingLeft = (20 * level) + 'px';

      if (workPackage.$loaded && workPackage.isLeaf) {
        hierarchyIndicator.innerHTML = `
            <span class="wp-table--leaf-indicator"></span>
        `;
      } else {
        const className = collapsed ? indicatorCollapsedClass : '';
        hierarchyIndicator.innerHTML = `
            <a class="wp-table--hierarchy-indicator ${className}">
              <span></span>
            </a>
        `;
      }
      return hierarchyIndicator;
  }

  private buildWithHierarchy(
    tbody:DocumentFragment,
    row:WorkPackageTableRow,
    additional:{[workPackageId:string]: WorkPackageResourceInterface}) {

    // Ancestor data [root, med, thisrow]
    const ancestors = row.object.ancestors;
    const ancestorGroups:string[] = [];
    ancestors.forEach((ancestor:WorkPackageResourceInterface, index:number) => {
      if (!additional[ancestor.id]) {
        let ancestorRow = this.buildAncestorRow(ancestor, ancestorGroups, index);
        // special case, root without parent
        if (index === 0) {
          // Simply append the root here
          tbody.appendChild(ancestorRow);

        } else {
          // This ancestor must be inserted in the last position of its root
          const parent = ancestors[index-1];
          this.insertIntoHierarchy(tbody, ancestorRow, parent.id);
        }

        additional[ancestor.id] = ancestor;
        ancestorGroups.push(`__hierarchy-group-${ancestor.id}`);
      }
    });

    // Insert this row to parent
    const parent = _.last(ancestors);
    const tr = this.buildEmptyRow(row);
    row.element = tr;
    this.insertIntoHierarchy(tbody, tr, parent.id);
  }

  /**
   * Append a row to the given parent hierarchy group.
   */
  private insertIntoHierarchy(tbody:DocumentFragment, tr:HTMLElement, parentId:string) {
    // Either append to the hierarchy group root (= the parentID row itself)
    const hierarchyRoot = `.__hierarchy-root-${parentId}`;
    // Or, if it has descendants, append to the LATEST of that set
    const hierarchyGroup = `.__hierarchy-group-${parentId}`;
    jQuery(tbody).find(`${hierarchyRoot},${hierarchyGroup}`).last().after(tr);
  }

  /**
   * Append an additional ancestor row that is not yet loaded
   */
  private buildAncestorRow(ancestor:WorkPackageResourceInterface, ancestorGroups:string[], index:number) {
    const tr = this.rowBuilder.createEmptyRow(ancestor);
    const columns = this.wpTableColumns.currentState;

    tr.classList.add(`__hierarchy-root-${ancestor.id}`, ...ancestorGroups);

    // Set available information for ID and subject column
    // and print hierarchy indicator at subject field.
    columns.forEach((column:string, i:number) => {
      const td = document.createElement('td');

      if (column === 'subject') {
        const textNode = document.createTextNode(ancestor.name);
        td.appendChild(this.buildHierarchyIndicator(ancestor, index));
        td.appendChild(textNode);
      }

      if (column === 'id') {
        const link = this.uiStateBuilder.linkToShow(
          ancestor.id,
          ancestor.subject,
          ancestor.id
        );

        td.appendChild(link);
      }

      tr.appendChild(td);
    });

    return tr;
  }
}


HierarchyRowsBuilder.$inject = ['wpTableColumns', 'states', 'I18n'];
