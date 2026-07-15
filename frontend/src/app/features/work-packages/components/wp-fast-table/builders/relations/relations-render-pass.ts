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
import { PrimaryRenderPass, RowRenderInfo } from '../primary-render-pass';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

export interface RelationRenderInfo extends RowRenderInfo {
  data:{
    label:string;
    columnId:string;
    relationType:RelationColumnType;
  };
}

export class RelationsRenderPass {
  @LazyInject() wpRelations:WorkPackageRelationsService;

  @LazyInject() wpTableColumns:WorkPackageViewColumnsService;

  @LazyInject() wpTableRelationColumns:WorkPackageViewRelationColumnsService;

  @LazyInject() states:States;

  @LazyInject() I18n:I18nService;

  public relationRowBuilder:RelationRowBuilder;

  renderType = 'relations';

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
    const rendered = [...this.tablePass.renderedOrder];
    rendered.forEach((row:RowRenderInfo) => {
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
    row:RowRenderInfo,
    label:string,
    column:QueryColumn,
    from:WorkPackageResource,
    to:WorkPackageResource,
    type:RelationColumnType,
  ) {
    relationRow.classList.add(...row.additionalClasses);
    this.relationRowBuilder.appendRelationLabel(
      relationRow,
      label,
      column.id,
    );

    // Insert next to the work package row
    // If no relations exist until here, directly under the row
    // otherwise as the last element of the relations
    // Insert into table
    this.tablePass.spliceRow(
      relationRow,
      `.${this.relationRowBuilder.classIdentifier(from)},.${relationGroupClass(from.id!)}`,
      {
        classIdentifier: this.relationRowBuilder.relationClassIdentifier(from, to),
        additionalClasses: row.additionalClasses.concat(['wp-table--relations-additional-row']),
        workPackage: to,
        belongsTo: from,
        renderType: this.renderType,
        hidden: row.hidden,
        data: {
          label,
          columnId: column.id,
          relationType: type,
        },
      } as RelationRenderInfo,
    );
  }

  public refreshRelationRow(
    renderedRow:RelationRenderInfo,
    workPackage:WorkPackageResource,
    oldRow:HTMLTableRowElement,
  ) {
    const newRow = this.relationRowBuilder.refreshRow(workPackage, oldRow);
    this.relationRowBuilder.appendRelationLabel(
      newRow,
      renderedRow.data.label,
      renderedRow.data.columnId,
    );

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
