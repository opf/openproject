import {Injectable} from '@angular/core';
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {WorkPackageViewHierarchiesService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {States} from "core-components/states.service";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {WorkPackageViewDisplayRepresentationService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";

@Injectable()
export class WorkPackageViewHierarchyIdentationService {

  constructor(private wpViewHierarchies:WorkPackageViewHierarchiesService,
              private wpDisplayRepresentation:WorkPackageViewDisplayRepresentationService,
              private states:States,
              private wpRelationHierarchy:WorkPackageRelationsHierarchyService,
              private wpCacheService:WorkPackageCacheService,
              private querySpace:IsolatedQuerySpace) {
  }

  /**
   * Return whether the current hierarchy mode is active
   */
  public get applicable():boolean {
    return this.wpViewHierarchies.isEnabled && this.wpDisplayRepresentation.isList;
  }

  /**
   * Returns whether the given work package can be indented in the current render order
   * @param workPackage
   */
  public canIndent(workPackage:WorkPackageResource):boolean {
    if (!workPackage.changeParent || !this.applicable) {
      return false;
    }

    const rendered = this.renderedWorkPackageIds;
    const index = rendered.indexOf(workPackage.id!);

    // We can never indent the first item
    if (index === 0) {
      return false;
    }

    // We can not indent work packages whose predecessors are already their ancestors
    const ancestors = workPackage.ancestorIds;
    const ancestorCount = ancestors.length;

    // We can always indent if the ancestor count is 0
    if (ancestorCount === 0) {
      return true;
    }

    // Otherwise, we can only indent if the predecessor is NOT the last ancestor
    const lastAncestor:string = ancestors[ancestorCount - 1];
    const predecessorId:string = rendered[index - 1];

    return predecessorId !== lastAncestor;
  }

  /**
   * Returns whether the given work package can be outdented
   * @param workPackage
   */
  public canOutdent(workPackage:WorkPackageResource):boolean {
    if (!workPackage.changeParent || !this.applicable) {
      return false;
    }

    // We can always outdent if the work package has a parent
    return !!workPackage.parent;
  }

  /**
   * Try to indent the work package.
   * @return a Promise with the change parent result
   */
  public async indent(workPackage:WorkPackageResource):Promise<unknown> {
    if (!this.canIndent(workPackage)) {
      return Promise.reject();
    }

    const rendered = this.renderedWorkPackageIds;
    const index = rendered.indexOf(workPackage.id!);
    const predecessorId:string = rendered[index - 1];

    // By default, assume we're going to insert under parent
    let newParentId = predecessorId;

    // If the predecessor is in an ancestor chain.
    // get the first element of the ancestor chain that workPackage is not in
    const predecessor = await this.wpCacheService.require(predecessorId);

    const difference = _.difference(predecessor.ancestorIds, workPackage.ancestorIds);
    if (difference && difference.length > 0) {
      newParentId = difference[0];
    }

    return this
      .wpRelationHierarchy
      .changeParent(workPackage, newParentId);
  }

  /**
   * Try to outdent the work package.
   * @return a Promise with the change parent result
   */
  public outdent(workPackage:WorkPackageResource):Promise<unknown> {
    if (!this.canOutdent(workPackage)) {
      return Promise.reject();
    }

    let newParentId:string|null = null;

    // If we have more than one ancestor,
    // just drop the last one
    const ancestorIds = workPackage.ancestorIds;
    const ancestorCount = ancestorIds.length;
    if (ancestorCount > 1) {
      newParentId = ancestorIds[ancestorCount - 2];
    }

    return this
      .wpRelationHierarchy
      .changeParent(workPackage, newParentId);
  }

  /**
   * Get the currently rendered work packages
   */
  private get renderedWorkPackageIds():string[] {
    return this.querySpace.renderedWorkPackageIds.getValueOr([]);
  }
}
