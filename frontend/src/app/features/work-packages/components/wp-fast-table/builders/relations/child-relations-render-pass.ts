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

import type { RenderedOccurrence } from 'core-app/features/work-packages/components/wp-fast-table/rendered-occurrence-ledger';
import {
  RelationsRenderPass,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/relations/relations-render-pass';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

export class ChildRelationsRenderPass extends RelationsRenderPass {
  renderType:RenderedOccurrence['renderType'] = 'child_relations';

  label = this.I18n.t('js.relation_labels.child');

  @LazyInject() apiV3Service:ApiV3Service;

  public render() {
    // If no relation column active, skip this pass
    if (!this.isApplicable) {
      return;
    }

    // Render for each original row, clone it since we're modifying the tablepass
    const rendered = [...this.tablePass.draft.occurrences];
    const missingChildIds:string[] = [];

    rendered.forEach((row) => {
      // We only care for rows that are natural work packages
      if (row.renderType !== 'primary' || !row.workPackage) {
        return;
      }

      // If the work package has no children, ignore
      const { workPackage } = row;
      if (!workPackage.children?.length) {
        return;
      }

      // Only if the work package has anything expanded
      const expanded = this.wpTableRelationColumns.getExpandFor(workPackage.id!);
      if (expanded === undefined) {
        return;
      }

      const column = this.wpTableColumns.findById(expanded)!;

      // Render the child relations
      workPackage.children.forEach((child) => {
        const target = this.states.workPackages.get(child.id!).value;

        if (!target) {
          missingChildIds.push(child.id!);
          return;
        }

        // Build each relation row (currently sorted by order defined in API)
        const [relationRow] = this.relationRowBuilder.buildEmptyRelationRow(
          workPackage,
          target,
        );

        // Augment any data for the belonging work package row to it
        this.renderRelationRow(relationRow, row, this.label, column, workPackage, target, 'children');
      });
    });

    this.loadMissingTargets(missingChildIds);
  }

  public get isApplicable() {
    return this.wpTableColumns.hasChildRelationsColumn();
  }

  private loadMissingTargets(ids:string[]) {
    const table = this.tablePass.workPackageTable;
    if (table.destroyed) return;
    const pending = table.requestRelationTargets(ids);

    if (pending.length === 0) {
      return;
    }

    void this.apiV3Service.work_packages.requireAll(pending)
      .then(() => {
        if (table.destroyed) return;
        table.redrawTableAndTimeline();
      })
      .catch(() => {
        table.releaseRelationTargets(pending);
      });
  }
}
