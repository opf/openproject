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

import { Injector } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import {
  WorkPackageRelationsService,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import {
  WorkPackageViewColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import {
  RelationColumnType,
  WorkPackageViewRelationColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { relationGroupClass, RelationRowBuilder } from './relation-row-builder';
import { PrimaryRenderPass } from '../primary-render-pass';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  type DraftOccurrence,
  relationOccurrenceKey,
  type RenderedOccurrence,
} from 'core-app/features/work-packages/components/wp-fast-table/rendered-occurrence-ledger';

export class RelationsRenderPass {
  @LazyInject() wpRelations:WorkPackageRelationsService;

  @LazyInject() wpTableColumns:WorkPackageViewColumnsService;

  @LazyInject() wpTableRelationColumns:WorkPackageViewRelationColumnsService;

  @LazyInject() states:States;

  @LazyInject() I18n:I18nService;

  public relationRowBuilder:RelationRowBuilder;

  renderType:RenderedOccurrence['renderType'] = 'relations';

  constructor(
    readonly injector:Injector,
    readonly table:WorkPackageTable,
    readonly tablePass:PrimaryRenderPass,
  ) {
    this.relationRowBuilder = new RelationRowBuilder(injector, table);
  }

  public render() {
    // If no relation column active, skip this pass
    if (!this.isApplicable) {
      return;
    }

    // Render for each original row, clone it since we're modifying the tablepass
    const rendered = [...this.tablePass.draft.occurrences];
    rendered.forEach((row) => {
      // We only care for rows that are natural work packages
      if (!row.workPackage) {
        return;
      }

      // If the work package has no relations, ignore
      const { workPackage } = row;
      const state = this.wpRelations.state(workPackage.id!);
      if (!state.hasValue() || Object.keys(state.value ?? {}).length === 0) {
        return;
      }

      this.wpTableRelationColumns.relationsToExtendFor(
        workPackage,
        state.value,
        (relation:RelationResource, column:QueryColumn, type:RelationColumnType) => {
          const denormalized = relation.denormalized(workPackage);
          const to = this.states.workPackages.get(denormalized.targetId).value!;

          // Build each relation row (currently sorted by order defined in API)
          const [relationRow, target] = this.relationRowBuilder.buildEmptyRelationRow(
            workPackage,
            to,
          );

          // Augment any data for the belonging work package row to it
          const label = this.relationTypeLabel(workPackage, to, relation, type);
          this.renderRelationRow(relationRow, row, label, column, workPackage, target, type);
        },
      );
    });
  }

  protected renderRelationRow(
    relationRow:HTMLTableRowElement,
    row:DraftOccurrence,
    label:string,
    column:QueryColumn,
    from:WorkPackageResource,
    to:WorkPackageResource,
    type:RelationColumnType,
  ) {
    const relation = { label, columnId: column.id, relationType: type };
    relationRow.classList.add(...row.additionalClasses);
    this.relationRowBuilder.appendRelationLabel(relationRow, relation.label, relation.columnId);

    // Insert next to the work package row
    // If no relations exist until here, directly under the row
    // otherwise as the last element of the relations
    // Insert into table
    this.tablePass.spliceRow(
      relationRow,
      `.${this.relationRowBuilder.classIdentifier(from)},.${relationGroupClass(from.id!)}`,
      {
        key: relationOccurrenceKey(type, from.id!, to.id!),
        classIdentifier: this.relationRowBuilder.relationClassIdentifier(from, to),
        additionalClasses: row.additionalClasses.concat(['wp-table--relations-additional-row']),
        workPackage: to,
        workPackageId: to.id!,
        renderType: this.renderType,
        hidden: row.hidden,
        relation,
      },
    );
  }

  public refreshRelationRow(
    occurrence:RenderedOccurrence,
    workPackage:WorkPackageResource,
    oldRow:HTMLTableRowElement,
  ):HTMLTableRowElement {
    const newRow = this.relationRowBuilder.refreshRow(workPackage, oldRow);
    if (occurrence.relation) {
      this.relationRowBuilder.appendRelationLabel(newRow, occurrence.relation.label, occurrence.relation.columnId);
    }

    return newRow;
  }

  private relationTypeLabel(from:WorkPackageResource, to:WorkPackageResource, relation:RelationResource, type:RelationColumnType) {
    const denormalized = relation.denormalized(from);

    let typeLabel = '';

    if (type === 'toType') {
      typeLabel = this.I18n.t(`js.relation_labels.${denormalized.reverseRelationType}`);
    }

    if (type === 'ofType') {
      typeLabel = to.type.name;
    }

    return typeLabel;
  }

  public get isApplicable() {
    return this.wpTableColumns.hasRelationColumns();
  }
}
