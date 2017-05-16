import {WorkPackageTable} from '../../../wp-fast-table';
import {WorkPackageResourceInterface} from '../../../../api/api-v3/hal-resources/work-package-resource.service';
import {SingleHierarchyRowBuilder} from './single-hierarchy-row-builder';
import {WorkPackageTableRow} from '../../../wp-table.interfaces';
import {
  collapsedGroupClass, hierarchyGroupClass,
  hierarchyRootClass
} from '../../../helpers/wp-table-hierarchy-helpers';
import {TableRenderPass} from '../table-render-pass';
import {Subject} from 'rxjs';
import {States} from '../../../../states.service';
import {$injectFields} from '../../../../angular/angular-injector-bridge.functions';
import {WorkPackageTableHierarchies} from '../../../wp-table-hierarchies';
import {rowClass} from '../../../helpers/wp-table-row-helpers';

export class HierarchyRenderPass extends TableRenderPass {
  public states:States;

  // Remember which rows were already rendered
  public rendered:{[workPackageId:string]: boolean};

  // Remember additional parents inserted that are not part of the results table
  public additionalParents:{[workPackageId:string]: WorkPackageResourceInterface};

  // Defer children to be rendered when their parent occurs later in the table
  public deferred:{[parentId:string]: WorkPackageResourceInterface[]};

  // Collapsed state
  private hierarchies:WorkPackageTableHierarchies;

  constructor(public workPackageTable:WorkPackageTable,
              public stopExisting$:Subject<undefined>,
              public rowBuilder:SingleHierarchyRowBuilder) {
    super(stopExisting$, workPackageTable);

    $injectFields(this, 'states');
  }

  protected prepare() {
    super.prepare();

    this.hierarchies = this.states.table.hierarchies.value!;
    this.rendered = {};
    this.additionalParents = {};
    this.deferred = {};
  }

  /**
   * Render the hierarchy table into the document fragment
   */
  protected doRender() {
    this.workPackageTable.rows.forEach((wpId:string) => {
      const row:WorkPackageTableRow = this.workPackageTable.rowIndex[wpId];
      const workPackage:WorkPackageResourceInterface = row.object;

      // If we need to defer this row, skip it for now
      if (this.deferInsertion(workPackage)) {
        return;
      }

      if (workPackage.ancestors.length) {
        // If we have ancestors, render it
        this.buildWithHierarchy(row);
      } else {
        // Render a work package root with no parents
        let [tr, hidden] = this.rowBuilder.buildEmpty(workPackage);
        row.element = tr;
        this.tableBody.appendChild(tr);
        this.timelineBody.appendChild(this.buildTimelineRow(workPackage));
        this.markRendered(workPackage, hidden);
      }

      // Render all potentially deferred rows
      this.renderAllDeferredChildren(workPackage);
    });
  }

  /**
   * If the given work package has a visible parent in the table, return true
   * and remember the work package until the parent is rendered.
   * @param workPackage
   * @returns {boolean}
   */
  public deferInsertion(workPackage:WorkPackageResourceInterface):boolean {
    const parentId = workPackage.parentId;

    // Will only defer if parent exists
    if (!parentId) {
      return false;
    }

    // Will only defer is parent is
    // 1. existent in the table results
    // 1. yet to be rendered
    if (this.workPackageTable.rowIndex[parentId] === undefined || this.rendered[parentId]) {
      return false;
    }

    const elements = this.deferred[parentId] || [];
    this.deferred[parentId] = elements.concat([workPackage]);

    return true;
  }

  /**
   * Render any deferred children of the given work package. If recursive children were
   * deferred, each of them will be passed through renderCallback.
   * @param workPackage
   */
  private renderAllDeferredChildren(workPackage:WorkPackageResourceInterface) {
    const wpId = workPackage.id.toString();
    const deferredChildren = this.deferred[wpId] || [];

    // If the work package has deferred children to render,
    // run them through the callback
    deferredChildren.forEach((child:WorkPackageResourceInterface) => {
      // Callback on the child itself
      const row:WorkPackageTableRow = this.workPackageTable.rowIndex[child.id];
      this.insertUnderParent(row, child.parentId.toString());

      // Descend into any children the child WP might have and callback
      this.renderAllDeferredChildren(child);
    });
  }

  private buildWithHierarchy(row:WorkPackageTableRow) {
    // Ancestor data [root, med, thisrow]
    const ancestors = row.object.ancestors;
    const ancestorGroups:string[] = [];

    // Iterate ancestors
    ancestors.forEach((ancestor:WorkPackageResourceInterface, index:number) => {

      // If we see the parent the first time,
      // build it as an additional row and insert it into the ancestry
      if (!this.rendered[ancestor.id]) {
        let [ancestorRow, hidden] = this.rowBuilder.buildAncestorRow(ancestor, ancestorGroups, index);
        // Insert the ancestor row, either right here if it's a root node
        // Or below the appropriate parent

        if (index === 0) {
          // Special case, first ancestor => root without parent
          this.tableBody.appendChild(ancestorRow);
          this.timelineBody.appendChild(this.buildTimelineRow(ancestor));
          this.markRendered(ancestor, hidden);
        } else {
          // This ancestor must be inserted in the last position of its root
          const parent = ancestors[index - 1];
          this.insertAtExistingHierarchy(ancestor, ancestorRow, parent.id, hidden);
        }

        // Remember we just added this extra ancestor row
        this.additionalParents[ancestor.id] = ancestor;
        // Push the correct ancestor groups for identifiying a hierarchy group
        ancestorGroups.push(hierarchyGroupClass(ancestor.id));
      }
    });

    // Insert this row to parent
    const parent = _.last(ancestors);
    this.insertUnderParent(row, parent.id);
  }

  /**
   * Insert the given node as a child of the parent
   * @param row
   * @param parentId
   */
  private insertUnderParent(row:WorkPackageTableRow, parentId:string) {
    const [tr, hidden] = this.rowBuilder.buildEmpty(row.object);
    row.element = tr;
    this.insertAtExistingHierarchy(row.object, tr, parentId, hidden);
  }

  /**
   * Mark the given work package as rendered
   * @param workPackage
   * @param hidden
   */
  private markRendered(workPackage:WorkPackageResourceInterface, hidden:boolean = false) {
    this.rendered[workPackage.id] = true;
    this.renderedOrder.push({
      workPackageId: workPackage.id.toString(),
      classIdentifier: rowClass(workPackage.id),
      hidden: hidden
    });
  }


  private buildTimelineRow(workPackage:WorkPackageResourceInterface):HTMLElement {
    const rowClasses = [hierarchyRootClass(workPackage.id)];

    if (_.isArray(workPackage.ancestors)) {
      workPackage.ancestors.forEach((ancestor) => {
        rowClasses.push(hierarchyGroupClass(ancestor.id));

        if (this.hierarchies.collapsed[ancestor.id]) {
          rowClasses.push(collapsedGroupClass(ancestor.id));
        }

      });
    }

    return this.timelineBuilder.build(workPackage, rowClasses);
  }

  /**
   * Append a row to the given parent hierarchy group.
   */
  private insertAtExistingHierarchy(workPackage:WorkPackageResourceInterface, el:HTMLElement, parentId:string, hidden:boolean) {
    // Either append to the hierarchy group root (= the parentID row itself)
    const hierarchyRoot = `.__hierarchy-root-${parentId}`;
    // Or, if it has descendants, append to the LATEST of that set
    const hierarchyGroup = `.__hierarchy-group-${parentId}`;

    // Insert into table
    const target = jQuery(this.tableBody).find(`${hierarchyRoot},${hierarchyGroup}`).last()
    target.after(el);

    // Mark as rendered at the given position
    const index = target.index();
    this.renderedOrder.splice(index + 1, 0, {
      workPackageId: workPackage.id.toString(),
      classIdentifier: rowClass(workPackage.id),
      hidden: hidden
    });

    // Insert into timeline
    const timelineRow = this.buildTimelineRow(workPackage);
    jQuery(this.timelineBody).find(`${hierarchyRoot},${hierarchyGroup}`).last().after(timelineRow);
  }
}
