//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { TableDragActionService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-action.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import {
  hierarchyGroupClass,
  hierarchyRootClass,
} from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-hierarchy-helpers';
import { relationRowClass, isInsideCollapsedGroup } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-row-helpers';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

export class HierarchyDragActionService extends TableDragActionService {
  @LazyInject() private wpTableHierarchies:WorkPackageViewHierarchiesService;

  @LazyInject() private relationHierarchyService:WorkPackageRelationsHierarchyService;

  @LazyInject() private apiV3Service:ApiV3Service;

  public get applies() {
    return this.wpTableHierarchies.isEnabled;
  }

  /**
   * Returns whether the given work package is movable
   */
  public canPickup(workPackage:WorkPackageResource):boolean {
    return !!workPackage.changeParent;
  }

  public handleDrop(workPackage:WorkPackageResource, el:HTMLElement):Promise<unknown> {
    return this.determineParent(el).then((parentId:string|null) => this.relationHierarchyService.changeParent(workPackage, parentId));
  }

  /**
   * Find an applicable parent element from the hierarchy information in the table.
   * @param el
   */
  private determineParent(el:Element):Promise<string|null> {
    let previous = el.previousElementSibling;
    const next = el.nextElementSibling;
    let parent = null;

    if (previous !== null && this.droppedIntoGroup(el, previous, next)) {
      // If the previous element is a relation row,
      // skip it until we find the real previous sibling
      const isRelationRow = previous.className.includes(relationRowClass());

      if (isRelationRow) {
        const relationRoot = this.findRelationRowRoot(previous);
        if (relationRoot == null) {
          return Promise.resolve(null);
        }
        previous = relationRoot;
      }

      const previousWpId = (previous as HTMLElement).dataset.workPackageId!;

      if (this.isHiearchyRoot(previous, previousWpId)) {
        const droppedIntoCollapsedGroup = isInsideCollapsedGroup(next);

        if (droppedIntoCollapsedGroup) {
          return this.determineParent(previous);
        }
        // If the sibling is a hierarchy root, return that sibling as new parent.
        parent = previousWpId;
      } else {
        // If the sibling is no hierarchy root, return its parent.
        // Thus, the dropped element will get the same hierarchy level as the sibling
        parent = this.loadParentOfWP(previousWpId);
      }
    }

    return Promise.resolve(parent);
  }

  private findRelationRowRoot(el:Element):Element|null {
    let previous = el.previousElementSibling;
    while (previous !== null) {
      if (!previous.className.includes(relationRowClass())) {
        return previous;
      }
      previous = previous.previousElementSibling;
    }

    return null;
  }

  private droppedIntoGroup(element:Element, previous:Element, next:Element | null):boolean {
    const inGroup = previous.className.includes(hierarchyGroupClass(''));
    const isRoot = previous.className.includes(hierarchyRootClass(''));
    let skipDroppedIntoGroup;

    if (inGroup || isRoot) {
      const elementGroups = Array.from(element.classList).filter((listClass) => listClass.includes('__hierarchy-group-')) || [];
      const previousGroups = Array.from(previous.classList).filter((listClass) => listClass.includes('__hierarchy-group-')) || [];
      const nextGroups = next && Array.from(next.classList).filter((listClass) => listClass.includes('__hierarchy-group-')) || [];
      const previousWpId = (previous as HTMLElement).dataset.workPackageId!;
      const isLastElementOfGroup = !nextGroups.some((nextGroup) => previousGroups.includes(nextGroup)) && !nextGroups.includes(hierarchyGroupClass(previousWpId));
      const elementAlreadyBelongsToGroup = elementGroups.some((elementGroup) => previousGroups.includes(elementGroup))
                                           || elementGroups.includes(hierarchyGroupClass(previousWpId));

      skipDroppedIntoGroup = isLastElementOfGroup && !elementAlreadyBelongsToGroup;
    }

    return !skipDroppedIntoGroup && inGroup || isRoot;
  }

  private isHiearchyRoot(previous:Element, previousWpId:string):boolean {
    return previous.classList.contains(hierarchyRootClass(previousWpId));
  }

  private loadParentOfWP(wpId:string):Promise<string|null> {
    return this
      .apiV3Service
      .work_packages
      .id(wpId)
      .get()
      .toPromise()
      .then((wp:WorkPackageResource) => Promise.resolve(wp.parent?.id || null));
  }
}
