import {Injector} from '@angular/core';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {States} from '../../../../states.service';
import {
  ancestorClassIdentifier,
  collapsedGroupClass,
  hierarchyGroupClass,
  hierarchyRootClass
} from '../../../helpers/wp-table-hierarchy-helpers';
import {WorkPackageTable} from '../../../wp-fast-table';
import {WorkPackageTableHierarchies} from '../../../wp-table-hierarchies';
import {WorkPackageTableRow} from '../../../wp-table.interfaces';
import {PrimaryRenderPass, RowRenderInfo} from '../../primary-render-pass';
import {additionalHierarchyRowClassName, SingleHierarchyRowBuilder} from './single-hierarchy-row-builder';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';

export class HierarchyRenderPass extends PrimaryRenderPass {

  private readonly tableState = this.injector.get(TableState);

  public states = this.injector.get(States);
  public wpCacheService = this.injector.get(WorkPackageCacheService);

  // Remember which rows were already rendered
  public rendered:{ [workPackageId:string]:boolean };

  // Remember additional parents inserted that are not part of the results table
  public additionalParents:{ [workPackageId:string]:WorkPackageResource };

  // Defer children to be rendered when their parent occurs later in the table
  public deferred:{ [parentId:string]:WorkPackageResource[] };

  // Collapsed state
  private hierarchies:WorkPackageTableHierarchies;

  constructor(public readonly injector:Injector,
              public workPackageTable:WorkPackageTable,
              public rowBuilder:SingleHierarchyRowBuilder) {
    super(injector, workPackageTable, rowBuilder);
  }

  protected prepare() {
    super.prepare();

    this.hierarchies = this.tableState.hierarchies.value!;
    this.rendered = {};
    this.additionalParents = {};
    this.deferred = {};
  }

  /**
   * Render the hierarchy table into the document fragment
   */
  protected doRender() {
    this.workPackageTable.originalRows.forEach((wpId:string) => {
      const row:WorkPackageTableRow = this.workPackageTable.originalRowIndex[wpId];
      const workPackage:WorkPackageResource = row.object;

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
        this.markRendered(workPackage, hidden);
      }

      // Render all potentially deferred rows
      this.renderAllDeferredChildren(workPackage);
    });
  }

  /**
   * If the given work package has a visible ancestor in the table, return true
   * and remember the work package until the ancestor is rendered.
   * @param workPackage
   * @returns {boolean}
   */
  public deferInsertion(workPackage:WorkPackageResource):boolean {
    const ancestors = workPackage.ancestors;

    // Will only defer if at least one ancestor exists
    if (ancestors.length === 0) {
      return false;
    }

    // Cases for wp
    // 1. No wp.ancestors in table -> Render them immediately (defer=false)
    // 2. Parent in table -> deffered[parent] = wp
    // 3. Parent not in table BUT a ancestor in table
    // -> deferred[a ancestor] = parent
    // -> deferred[parent] = wp
    // 4. Any ancestor already rendered -> Render normally (don't defer)
    var ancestorChain = ancestors.concat([workPackage]);
    for (let i = ancestorChain.length - 2; i >= 0; --i) {
      const parent = ancestorChain[i];
      const child = ancestorChain[i + 1];

      const inTable = this.workPackageTable.originalRowIndex[parent.id];
      const alreadyRendered = this.rendered[parent.id];

      if (alreadyRendered) {
        // parent is already rendered.
        // Don't defer, but render all intermediate parents below it
        return false;
      }

      if (inTable) {
        // Get the current elements
        let elements = this.deferred[parent.id] || [];
        // Append to them the child and all children below
        let newElements:WorkPackageResource[] = ancestorChain.slice(i + 1, ancestorChain.length);
        newElements = newElements.map(child => this.wpCacheService.state(child.id).value!);
        // Append all new elements
        elements = elements.concat(newElements);
        // Remove duplicates (Regression #29652)
        this.deferred[parent.id] = _.uniqBy(elements, el => el.id);
        return true;
      }
      // Otherwise, continue the chain upwards
    }

    return false;
  }


  /**
   * Render any deferred children of the given work package. If recursive children were
   * deferred, each of them will be passed through renderCallback.
   * @param workPackage
   */
  private renderAllDeferredChildren(workPackage:WorkPackageResource) {
    const wpId = workPackage.id.toString();
    const deferredChildren = this.deferred[wpId] || [];

    // If the work package has deferred children to render,
    // run them through the callback
    deferredChildren.forEach((child:WorkPackageResource) => {
      this.insertUnderParent(this.getOrBuildRow(child), child.parent);

      // Descend into any children the child WP might have and callback
      this.renderAllDeferredChildren(child);
    });
  }

  private getOrBuildRow(workPackage:WorkPackageResource) {
    let row:WorkPackageTableRow = this.workPackageTable.originalRowIndex[workPackage.id];

    if (!row) {
      row = {object: workPackage} as WorkPackageTableRow;
    }

    return row;
  }

  private buildWithHierarchy(row:WorkPackageTableRow) {
    // Ancestor data [root, med, thisrow]
    const ancestors = row.object.ancestors;
    const ancestorGroups:string[] = [];

    // Iterate ancestors
    ancestors.forEach((el:WorkPackageResource, index:number) => {
      const ancestor = this.states.workPackages.get(el.id).value!;


      // If we see the parent the first time,
      // build it as an additional row and insert it into the ancestry
      if (!this.rendered[ancestor.id]) {
        let [ancestorRow, hidden] = this.rowBuilder.buildAncestorRow(ancestor, ancestorGroups, index);
        // Insert the ancestor row, either right here if it's a root node
        // Or below the appropriate parent

        if (index === 0) {
          // Special case, first ancestor => root without parent
          this.tableBody.appendChild(ancestorRow);
          this.markRendered(ancestor, hidden, true);
        } else {
          // This ancestor must be inserted in the last position of its root
          const parent = ancestors[index - 1];
          this.insertAtExistingHierarchy(ancestor, ancestorRow, parent, hidden, true);
        }

        // Remember we just added this extra ancestor row
        this.additionalParents[ancestor.id] = ancestor;
      }

      // Push the correct ancestor groups for identifiying a hierarchy group
      ancestorGroups.push(hierarchyGroupClass(ancestor.id));
      ancestors.slice(0, index).forEach((previousAncestor) => {
        ancestorGroups.push(hierarchyGroupClass(previousAncestor.id));
      });
    });

    // Insert this row to parent
    const parent = _.last(ancestors);
    this.insertUnderParent(row, parent!);
  }

  /**
   * Insert the given node as a child of the parent
   * @param row
   * @param parentId
   */
  private insertUnderParent(row:WorkPackageTableRow, parent:WorkPackageResource) {
    const [tr, hidden] = this.rowBuilder.buildEmpty(row.object);
    row.element = tr;
    this.insertAtExistingHierarchy(row.object, tr, parent, hidden, false);
  }

  /**
   * Mark the given work package as rendered
   * @param workPackage
   * @param hidden
   */
  private markRendered(workPackage:WorkPackageResource, hidden:boolean = false, isAncestor:boolean = false) {
    this.rendered[workPackage.id] = true;
    this.renderedOrder.push(this.buildRenderInfo(workPackage, hidden, isAncestor));
  }

  public ancestorClasses(workPackage:WorkPackageResource) {
    const rowClasses = [hierarchyRootClass(workPackage.id)];

    if (_.isArray(workPackage.ancestors)) {
      workPackage.ancestors.forEach((ancestor) => {
        rowClasses.push(hierarchyGroupClass(ancestor.id));

        if (this.hierarchies.collapsed[ancestor.id]) {
          rowClasses.push(collapsedGroupClass(ancestor.id));
        }

      });
    }

    return rowClasses;
  }

  /**
   * Append a row to the given parent hierarchy group.
   */
  private insertAtExistingHierarchy(workPackage:WorkPackageResource,
                                    el:HTMLElement,
                                    parent:WorkPackageResource,
                                    hidden:boolean,
                                    isAncestor:boolean) {
    // Either append to the hierarchy group root (= the parentID row itself)
    const hierarchyRoot = `.__hierarchy-root-${parent.id}`;
    // Or, if it has descendants, append to the LATEST of that set
    const hierarchyGroup = `.__hierarchy-group-${parent.id}`;

    // Insert into table
    this.spliceRow(
      el,
      `${hierarchyRoot},${hierarchyGroup}`,
      this.buildRenderInfo(workPackage, hidden, isAncestor)
    );

    this.rendered[workPackage.id] = true;
  }

  private buildRenderInfo(workPackage:WorkPackageResource, hidden:boolean, isAncestor:boolean):RowRenderInfo {
    let info:any = {
      workPackage: workPackage,
      renderType: 'primary',
      hidden: hidden
    };

    if (isAncestor) {
      info.additionalClasses = [additionalHierarchyRowClassName].concat(this.ancestorClasses(workPackage));
      info.classIdentifier = ancestorClassIdentifier(workPackage.id);
    } else {
      info.additionalClasses = this.ancestorClasses(workPackage);
      info.classIdentifier = this.rowBuilder.classIdentifier(workPackage);
    }

    return info as RowRenderInfo;
  }
}
