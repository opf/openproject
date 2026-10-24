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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PrimaryRenderPass } from 'core-app/features/work-packages/components/wp-fast-table/builders/primary-render-pass';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { ancestorClassIdentifier } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-hierarchy-helpers';
import { WorkPackageViewHierarchies } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-table-hierarchies';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import {
  ancestorOccurrenceKey,
  type DraftOccurrence,
  type OccurrenceKey,
  wpOccurrenceKey,
} from 'core-app/features/work-packages/components/wp-fast-table/rendered-occurrence-ledger';
import { additionalHierarchyRowClassName, SingleHierarchyRowBuilder } from './single-hierarchy-row-builder';
import { hierarchyOrder } from './hierarchy-order';

export class HierarchyRenderPass extends PrimaryRenderPass {
  @LazyInject() querySpace:IsolatedQuerySpace;

  @LazyInject() states:States;

  @LazyInject() wpTableHierarchies:WorkPackageViewHierarchiesService;

  // Remember which rows were already rendered
  readonly rendered:Record<string, boolean> = {};

  // Collapsed state
  private hierarchies:WorkPackageViewHierarchies;

  // Build a map of hierarchy elements present in the table
  // with at least a visible child
  public parentsWithVisibleChildren:Record<string, boolean> = {};

  constructor(public readonly injector:Injector,
    public workPackageTable:WorkPackageTable,
    public rowBuilder:SingleHierarchyRowBuilder) {
    super(injector, workPackageTable, rowBuilder);
  }

  protected prepare() {
    super.prepare();

    this.hierarchies = this.wpTableHierarchies.current;

    Object.values(this.workPackageTable.originalRowIndex).forEach((row) => {
      row.object.getAncestors().forEach((ancestor:WorkPackageResource) => {
        this.parentsWithVisibleChildren[ancestor.id!] = true;
      });
    });

    this.rowBuilder.parentsWithVisibleChildren = this.parentsWithVisibleChildren;
  }

  /**
   * Render the hierarchy table into the document fragment
   */
  protected doRender() {
    const results = this.workPackageTable.originalRows.map((wpId) => this.workPackageTable.originalRowIndex[wpId].object);
    const ancestors = new Map(results.flatMap((wp) => wp.getAncestors()).map((ancestor) => [ancestor.id!, ancestor]));
    const order = hierarchyOrder(
      results.map((wp) => ({ id: wp.id!, ancestorIds: wp.getAncestors().map((ancestor) => ancestor.id!) })),
      this.querySpace.results.value?.rowPositions,
    );

    order.forEach((id) => {
      const row = this.workPackageTable.originalRowIndex[id];
      if (row) {
        const [tr, hidden] = this.rowBuilder.buildEmpty(row.object);
        this.markRendered(tr, row.object, hidden);
      } else {
        const ancestor = this.states.workPackages.get(id).getValueOr(ancestors.get(id)!);
        const [tr, hidden] = this.rowBuilder.buildAncestorRow(ancestor);
        this.markRendered(tr, ancestor, hidden, true);
      }
    });
  }

  /**
   * Mark the given work package as rendered
   * @param workPackage
   * @param hidden
   * @param isAncestor
   */
  private markRendered(row:HTMLTableRowElement, workPackage:WorkPackageResource, hidden = false, isAncestor = false) {
    this.rendered[workPackage.id!] = true;
    this.registerAppended(row, this.buildOccurrence(workPackage, hidden, isAncestor));
  }

  private occurrenceKey(workPackage:WorkPackageResource, isAncestor:boolean):OccurrenceKey {
    return isAncestor ? ancestorOccurrenceKey(workPackage.id!) : wpOccurrenceKey(workPackage.id!);
  }

  private buildOccurrence(workPackage:WorkPackageResource, hidden:boolean, isAncestor:boolean):Omit<DraftOccurrence, 'element'> {
    const [ancestorClasses] = this.rowBuilder.ancestorRowData(workPackage);

    return {
      key: this.occurrenceKey(workPackage, isAncestor),
      classIdentifier: isAncestor ? ancestorClassIdentifier(workPackage.id!) : this.rowBuilder.classIdentifier(workPackage),
      additionalClasses: isAncestor ? [additionalHierarchyRowClassName].concat(ancestorClasses) : ancestorClasses,
      workPackage,
      workPackageId: workPackage.id!,
      renderType: 'primary',
      hidden,
      level: workPackage.getAncestors().length + 1,
    };
  }
}
