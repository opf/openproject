import {PlainRowsBuilder} from "../plain/plain-rows-builder";
import {WorkPackageTableColumnsService} from "../../../state/wp-table-columns.service";
import {States} from "../../../../states.service";
import {WorkPackageTableHierarchiesService} from "../../../state/wp-table-hierarchy.service";
import {WorkPackageTable} from "../../../wp-fast-table";
import {injectorBridge} from "../../../../angular/angular-injector-bridge.functions";
import {WorkPackageResourceInterface} from "../../../../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageTableRow} from "../../../wp-table.interfaces";
import {SingleHierarchyRowBuilder} from "./single-hierarchy-row-builder";
import {hierarchyGroupClass} from "../../../helpers/wp-table-hierarchy-helpers";


export class HierarchyRowsBuilder extends PlainRowsBuilder {
  // Injections
  public states:States;
  public wpTableColumns:WorkPackageTableColumnsService;
  public wpTableHierarchies:WorkPackageTableHierarchiesService;
  public I18n:op.I18n;

  // Row builders
  protected rowBuilder:SingleHierarchyRowBuilder;
  protected refreshBuilder:SingleHierarchyRowBuilder;



  // The group expansion state
  constructor(public workPackageTable: WorkPackageTable) {
    super(workPackageTable);
    injectorBridge(this);
  }

  /**
   * The hierarchy builder is only applicable if the hierachy mode is active
   */
  public isApplicable(_table:WorkPackageTable) {
    return this.wpTableHierarchies.isEnabled;
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

  protected setupRowBuilders() {
    this.rowBuilder = new SingleHierarchyRowBuilder(this.stopExisting$, this.workPackageTable);
    this.refreshBuilder = this.rowBuilder;
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
        let ancestorRow = this.rowBuilder.buildAncestorRow(table, ancestor, ancestorGroups, index);
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

}


HierarchyRowsBuilder.$inject = ['wpTableColumns', 'wpTableHierarchies', 'states', 'I18n'];
