import {collapsedGroupClass, hierarchyGroupClass, hierarchyRootClass} from '../../helpers/wp-table-hierarchy-helpers';
import {WorkPackageTableHierarchyService} from '../../state/wp-table-hierarchy.service';
import {UiStateLinkBuilder} from '../ui-state-link-builder';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {QueryColumn} from '../../../api/api-v3/hal-resources/query-resource.service';
import {WorkPackageTableRow} from '../../wp-table.interfaces';
import {PlainRowsBuilder} from './plain-rows-builder';
import {States} from '../../../states.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {WorkPackageTable} from '../../wp-fast-table';

export const indicatorCollapsedClass = '-hierarchy-collapsed';
export const hierarchyCellClassName = 'wp-table--hierarchy-span';

export class HierarchyRowsBuilder extends PlainRowsBuilder {
  // Injections
  public states:States;
  public wpTableColumns:WorkPackageTableColumnsService;
  public wpTableHierarchy:WorkPackageTableHierarchyService;
  public I18n:op.I18n;

  public uiStateBuilder = new UiStateLinkBuilder();
  public text:{
    leaf:(level:number) => string;
    expanded:(level:number) => string;
    collapsed:(level:number) => string;
  };

  // The group expansion state
  constructor(workPackageTable: WorkPackageTable) {
    super(workPackageTable);
    injectorBridge(this);

    this.text = {
      leaf: (level:number) => this.I18n.t('js.work_packages.hierarchy.leaf', { level: level }),
      expanded: (level:number) => this.I18n.t('js.work_packages.hierarchy.children_expanded', { level: level }),
      collapsed: (level:number) => this.I18n.t('js.work_packages.hierarchy.children_collapsed', { level: level }),
    };
  }

  /**
   * The hierarchy builder is only applicable if the hierachy mode is active
   */
  public isApplicable(table:WorkPackageTable) {
    return this.wpTableHierarchy.isEnabled;
  }

  /**
   * Rebuild the entire grouped tbody from the given table
   * @param table
   */
  public internalBuildRows(table:WorkPackageTable):DocumentFragment {
    // Remember all additional rows drawn for hierarchy
    const additional:{[workPackageId:string]: WorkPackageResourceInterface} = {};

    const tbodyContent = document.createDocumentFragment();

    table.rows.forEach((wpId:string) => {
      let row:WorkPackageTableRow = table.rowIndex[wpId];

      // If this row was already rendered in a hierarchy, ignore it here
      if (additional[row.workPackageId]) {
        return;
     }

      // If we have ancestors
      if (row.object.ancestors.length) {
        this.buildWithHierarchy(table, tbodyContent, row, additional);
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

  /**
   * Refresh a single row after structural changes.
   * Remembers and re-adds the hierarchy indicator if neccessary.
   */
  public refreshRow(row:WorkPackageTableRow, table:WorkPackageTable):HTMLElement|null {
    // Remove any old hierarchy
    const newRow = super.refreshRow(row, table);

    if (newRow) {
      jQuery(newRow).find(`.wp-table--hierarchy-span`).remove();
      this.appendHierarchyIndicator(row.object, newRow);
    }

    return newRow;
  }

  public buildEmptyRow(row:WorkPackageTableRow, table?:WorkPackageTable, level?:number) {
    const element = this.rowBuilder.buildEmpty(row.object);
    const state = this.wpTableHierarchy.currentState;

    row.object.ancestors.forEach((ancestor:WorkPackageResourceInterface) => {
      element.classList.add(`__hierarchy-group-${ancestor.id}`);

      if (state.collapsed[ancestor.id]) {
        element.classList.add(collapsedGroupClass(ancestor.id));
      }
    });

    element.classList.add(`__hierarchy-root-${row.object.id}`);
    this.appendHierarchyIndicator(row.object, element);
    return element;
  }

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
      const collapsed = this.wpTableHierarchy.collapsed(workPackage.id);
      hierarchyIndicator.classList.add(hierarchyCellClassName);
      hierarchyIndicator.style.width = 25 + (20 * level) + 'px';

      if (workPackage.$loaded && workPackage.isLeaf) {
        hierarchyIndicator.innerHTML = `
            <span tabindex="0" class="wp-table--leaf-indicator">
              <span class="hidden-for-sighted">${this.text.leaf(level)}</span>
            </span>
        `;
      } else {
        const className = collapsed ? indicatorCollapsedClass : '';
        hierarchyIndicator.innerHTML = `
            <a href tabindex="0" role="button" class="wp-table--hierarchy-indicator ${className}">
              <span class="wp-table--hierarchy-indicator-icon"></span>
              <span class="wp-table--hierarchy-indicator-expanded hidden-for-sighted">${this.text.expanded(level)}</span>
              <span class="wp-table--hierarchy-indicator-collapsed hidden-for-sighted">${this.text.collapsed(level)}</span>
            </a>
        `;
      }
      return hierarchyIndicator;
  }

  private buildWithHierarchy(
    table:WorkPackageTable,
    tbody:DocumentFragment,
    row:WorkPackageTableRow,
    additional:{[workPackageId:string]: WorkPackageResourceInterface}) {

    // Ancestor data [root, med, thisrow]
    const ancestors = row.object.ancestors;
    const ancestorGroups:string[] = [];
    ancestors.forEach((ancestor:WorkPackageResourceInterface, index:number) => {
      if (!additional[ancestor.id]) {
        let ancestorRow = this.buildAncestorRow(table, ancestor, ancestorGroups, index);
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
        ancestorGroups.push(hierarchyGroupClass(ancestor.id));
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
  private buildAncestorRow(
    table:WorkPackageTable,
    ancestor:WorkPackageResourceInterface,
    ancestorGroups:string[],
    index:number):HTMLElement {

    const loadedRow = table.rowIndex[ancestor.id];

    if (loadedRow) {
      const tr =  this.buildEmptyRow(loadedRow, table, index);
      tr.classList.add('wp-table--hierarchy-aditional-row');
      return tr;
    }

    const tr = this.rowBuilder.createEmptyRow(ancestor);
    const columns = this.wpTableColumns.getColumns();

    tr.classList.add(`wp-table--hierarchy-aditional-row`, hierarchyRootClass(ancestor.id), ...ancestorGroups);

    // Set available information for ID and subject column
    // and print hierarchy indicator at subject field.
    columns.forEach((column:QueryColumn, i:number) => {
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
        td.classList.add('-short', 'hierarchy-row--id-cell');
      }

      tr.appendChild(td);
    });

    // Append details icon
    const td = document.createElement('td');
    tr.appendChild(td);

    return tr;
  }
}


HierarchyRowsBuilder.$inject = ['wpTableColumns', 'wpTableHierarchy', 'states', 'I18n'];
