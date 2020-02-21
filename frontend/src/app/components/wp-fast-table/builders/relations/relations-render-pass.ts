import {Injector} from '@angular/core';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {PrimaryRenderPass, RowRenderInfo} from '../primary-render-pass';
import {relationGroupClass, RelationRowBuilder} from './relation-row-builder';
import {QueryColumn} from 'core-components/wp-query/query-column';
import {WorkPackageRelationsService} from "core-components/wp-relations/wp-relations.service";
import {WorkPackageTable} from "core-components/wp-fast-table/wp-fast-table";
import {WorkPackageViewColumnsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service";
import {
  RelationColumnType,
  WorkPackageViewRelationColumnsService
} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-relation-columns.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export interface RelationRenderInfo extends RowRenderInfo {
  data:{
    relation:RelationResource;
    columnId:string;
    relationType:RelationColumnType;
  };
}

export class RelationsRenderPass {
  @InjectField() wpRelations:WorkPackageRelationsService;
  @InjectField() wpTableColumns:WorkPackageViewColumnsService;
  @InjectField() wpTableRelationColumns:WorkPackageViewRelationColumnsService;

  public relationRowBuilder:RelationRowBuilder;

  constructor(public readonly injector:Injector,
              private table:WorkPackageTable,
              private tablePass:PrimaryRenderPass) {

    this.relationRowBuilder = new RelationRowBuilder(injector, table);
  }

  public render() {
    // If no relation column active, skip this pass
    if (!this.isApplicable) {
      return;
    }

    // Render for each original row, clone it since we're modifying the tablepass
    const rendered = _.clone(this.tablePass.renderedOrder);
    rendered.forEach((row:RowRenderInfo, position:number) => {

      // We only care for rows that are natural work packages
      if (!row.workPackage) {
        return;
      }

      // If the work package has no relations, ignore
      const workPackage = row.workPackage;
      const fromId = workPackage.id!;
      const state = this.wpRelations.state(fromId);
      if (!state.hasValue() || _.size(state.value) === 0) {
        return;
      }

      this.wpTableRelationColumns.relationsToExtendFor(workPackage,
        state.value,
        (relation:RelationResource, column:QueryColumn, type:any) => {

          // Build each relation row (currently sorted by order defined in API)
          const [relationRow, target] = this.relationRowBuilder.buildEmptyRelationRow(
            workPackage,
            relation,
            type
          );

          // Augment any data for the belonging work package row to it
          relationRow.classList.add(...row.additionalClasses);
          this.relationRowBuilder.appendRelationLabel(jQuery(relationRow),
            workPackage,
            relation,
            column.id,
            type);

          // Insert next to the work package row
          // If no relations exist until here, directly under the row
          // otherwise as the last element of the relations
          // Insert into table
          this.tablePass.spliceRow(
            relationRow,
            `.${this.relationRowBuilder.classIdentifier(workPackage)},.${relationGroupClass(fromId)}`,
            {
              classIdentifier: this.relationRowBuilder.relationClassIdentifier(workPackage, target),
              additionalClasses: row.additionalClasses.concat(['wp-table--relations-aditional-row']),
              workPackage: target,
              belongsTo: workPackage,
              renderType: 'relations',
              hidden: row.hidden,
              data: {
                relation: relation,
                columnId: column.id,
                relationType: type
              }
            } as RelationRenderInfo
          );
        });
    });
  }

  public refreshRelationRow(renderedRow:RelationRenderInfo,
                            workPackage:WorkPackageResource,
                            oldRow:JQuery) {
    const newRow = this.relationRowBuilder.refreshRow(workPackage, oldRow);
    this.relationRowBuilder.appendRelationLabel(newRow,
      renderedRow.belongsTo!,
      renderedRow.data.relation,
      renderedRow.data.columnId,
      renderedRow.data.relationType);

    return newRow;
  }

  private get isApplicable() {
    return this.wpTableColumns.hasRelationColumns();
  }
}
