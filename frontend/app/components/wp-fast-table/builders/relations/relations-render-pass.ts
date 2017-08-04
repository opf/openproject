import {PrimaryRenderPass, RowRenderInfo} from '../primary-render-pass';
import {WorkPackageTable} from '../../wp-fast-table';
import {
  RelationColumnType,
  WorkPackageTableRelationColumnsService
} from '../../state/wp-table-relation-columns.service';
import {$injectFields} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {relationGroupClass, RelationRowBuilder} from './relation-row-builder';
import {WorkPackageRelationsService} from '../../../wp-relations/wp-relations.service';
import {WorkPackageEditForm} from '../../../wp-edit-form/work-package-edit-form';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {RelationResource} from '../../../api/api-v3/hal-resources/relation-resource.service';
import {WorkPackageChangeset} from '../../../wp-edit-form/work-package-changeset';

export interface RelationRenderInfo extends RowRenderInfo {
  data:{
    relation:RelationResource;
    columnId:string;
    relationType:RelationColumnType;
  };
}

export class RelationsRenderPass {
  public wpRelations:WorkPackageRelationsService;
  public wpTableColumns:WorkPackageTableColumnsService;
  public wpTableRelationColumns:WorkPackageTableRelationColumnsService;

  public relationRowBuilder:RelationRowBuilder;

  constructor(private table:WorkPackageTable, private tablePass:PrimaryRenderPass) {
    $injectFields(this, 'wpRelations', 'wpTableColumns', 'wpTableRelationColumns');

    this.relationRowBuilder = new RelationRowBuilder(table);
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
      const fromId = workPackage.id;
      const state = this.wpRelations.state(fromId);
      if (!state.hasValue() || _.size(state.value!) === 0) {
        return;
      }

      this.wpTableRelationColumns.relationsToExtendFor(workPackage,
        state.value!,
        (relation, column, type) => {

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
                            workPackage:WorkPackageResourceInterface,
                            changeset:WorkPackageChangeset,
                            oldRow:JQuery) {
    const newRow = this.relationRowBuilder.refreshRow(workPackage, changeset, oldRow);
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
