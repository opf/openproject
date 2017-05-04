import {WorkPackageTable} from "../../../wp-fast-table";
import {WorkPackageTableRow} from "../../../wp-table.interfaces";
import {WorkPackageResourceInterface} from "../../../../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageTableHierarchiesService} from "../../../state/wp-table-hierarchy.service";
import {$injectFields} from "../../../../angular/angular-injector-bridge.functions";
import {Observable} from 'rxjs';
import {RowRefreshBuilder} from "../../rows/row-refresh-builder";
import {WorkPackageEditForm} from "../../../../wp-edit-form/work-package-edit-form";
import {collapsedGroupClass, hierarchyRootClass} from "../../../helpers/wp-table-hierarchy-helpers";
import {QueryColumn} from "../../../../api/api-v3/hal-resources/query-resource.service";
import {UiStateLinkBuilder} from "../../ui-state-link-builder";

export const indicatorCollapsedClass = '-hierarchy-collapsed';
export const hierarchyCellClassName = 'wp-table--hierarchy-span';

export class SingleHierarchyRowBuilder extends RowRefreshBuilder {
  // Injected
  public wpTableHierarchies:WorkPackageTableHierarchiesService;

  public uiStateBuilder = new UiStateLinkBuilder();
  public text:{
    leaf:(level:number) => string;
    expanded:(level:number) => string;
    collapsed:(level:number) => string;
  };

  constructor(protected stopExisting$: Observable<any>, protected workPackageTable: WorkPackageTable) {
    super(stopExisting$, workPackageTable);
    $injectFields(this, 'wpTableHierarchies');

    this.text = {
      leaf: (level:number) => this.I18n.t('js.work_packages.hierarchy.leaf', { level: level }),
      expanded: (level:number) => this.I18n.t('js.work_packages.hierarchy.children_expanded', { level: level }),
      collapsed: (level:number) => this.I18n.t('js.work_packages.hierarchy.children_collapsed', { level: level }),
    };
  }

  /**
   * Refresh a single row after structural changes.
   * Remembers and re-adds the hierarchy indicator if neccessary.
   */
  public refreshRow(row: WorkPackageTableRow, editForm: WorkPackageEditForm | undefined): HTMLElement | null {
    // Remove any old hierarchy
    const newRow = super.refreshRow(row, editForm);

    if (newRow) {
      jQuery(newRow).find(`.wp-table--hierarchy-span`).remove();
      this.appendHierarchyIndicator(row.object, newRow);
    }

    return newRow;
  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmpty(workPackage:WorkPackageResourceInterface) {
    const element = super.buildEmpty(workPackage);
    const state = this.wpTableHierarchies.currentState;

    workPackage.ancestors.forEach((ancestor:WorkPackageResourceInterface) => {
      element.classList.add(`__hierarchy-group-${ancestor.id}`);

      if (state.collapsed[ancestor.id]) {
        element.classList.add(collapsedGroupClass(ancestor.id));
      }
    });

    element.classList.add(`__hierarchy-root-${workPackage.id}`);
    this.appendHierarchyIndicator(workPackage, element);
    return element;
  }

  /**
   * Append an additional ancestor row that is not yet loaded
   */
  public buildAncestorRow(
    table:WorkPackageTable,
    ancestor:WorkPackageResourceInterface,
    ancestorGroups:string[],
    index:number):HTMLElement {

    const loadedRow = table.rowIndex[ancestor.id];

    if (loadedRow) {
      const tr =  this.buildEmpty(loadedRow.object);
      tr.classList.add('wp-table--hierarchy-aditional-row');
      return tr;
    }

    const tr = this.createEmptyRow(ancestor);
    const columns = this.wpTableColumns.getColumns();

    tr.classList.add(`wp-table--hierarchy-aditional-row`, hierarchyRootClass(ancestor.id), ...ancestorGroups);

    // Set available information for ID and subject column
    // and print hierarchy indicator at subject field.
    columns.forEach((column:QueryColumn) => {
      const td = document.createElement('td');

      if (column.id === 'subject') {
        const textNode = document.createTextNode(ancestor.name);
        td.appendChild(this.buildHierarchyIndicator(ancestor, index));
        td.appendChild(textNode);
      }

      if (column.id === 'id') {
        const link = this.uiStateBuilder.linkToShow(
          ancestor.id,
          ancestor.subject,
          ancestor.id
        );

        td.appendChild(link);
        td.classList.add('hierarchy-row--id-cell');
      }

      tr.appendChild(td);
    });

    // Append details icon
    const td = document.createElement('td');
    tr.appendChild(td);

    return tr;
  }

  /**
   * Append to the row of hierarchy level <level> a hierarchy indicator.
   * @param workPackage
   * @param row
   * @param level
   */
  private appendHierarchyIndicator(workPackage:WorkPackageResourceInterface, row:HTMLElement, level?:number):void {
    const jRow = jQuery(row);
    const hierarchyElement = this.buildHierarchyIndicator(workPackage, level);

    jRow.find('td.subject')
        .addClass('-with-hierarchy')
        .prepend(hierarchyElement);
  }

  /**
   * Build the hierarchy indicator at the given indentation level.
   */
  private buildHierarchyIndicator(workPackage:WorkPackageResourceInterface, index:number|null = null):HTMLElement {
    const level = index === null ? workPackage.ancestors.length : index;
    const hierarchyIndicator = document.createElement('span');
    const collapsed = this.wpTableHierarchies.collapsed(workPackage.id);
    hierarchyIndicator.classList.add(hierarchyCellClassName);
    hierarchyIndicator.style.width = 25 + (20 * level) + 'px';

    if (workPackage.$loaded && !this.hasChildrenInTable(workPackage)) {
      hierarchyIndicator.innerHTML = `
            <span tabindex="0" class="wp-table--leaf-indicator">
              <span class="hidden-for-sighted">${this.text.leaf(level)}</span>
            </span>
        `;
    } else {
      const className = collapsed ? indicatorCollapsedClass : '';
      hierarchyIndicator.innerHTML = `
            <a href tabindex="0" role="button" class="wp-table--hierarchy-indicator ${className}">
              <span class="wp-table--hierarchy-indicator-icon" aria-hidden="true"></span>
              <span class="wp-table--hierarchy-indicator-expanded hidden-for-sighted">${this.text.expanded(level)}</span>
              <span class="wp-table--hierarchy-indicator-collapsed hidden-for-sighted">${this.text.collapsed(level)}</span>
            </a>
        `;
    }
    return hierarchyIndicator;
  }

  /**
   * Returns whether any of the children of this work package
   * are visible in the table results.
   */
  private hasChildrenInTable(workPackage:WorkPackageResourceInterface) {
    if (workPackage.isLeaf) {
      return false; // Work Package has no children at all
    }

    const rows = this.workPackageTable.rows;
    const total = rows.length;
    if (rows[total - 1] === workPackage.id) {
      return false; // Last element, can have no children
    }

    // If immediately following child has element
    const row = this.workPackageTable.rowIndex[workPackage.id];
    const nextIndex = row.position + 1;

    if (nextIndex < total) {
      const nextId = rows[nextIndex].toString();
      return !!_.find(workPackage.children, (child:WorkPackageResourceInterface) => child.idFromLink === nextId);
    }

    return false;
  }
}

SingleHierarchyRowBuilder.$inject = ['states', 'I18n'];
