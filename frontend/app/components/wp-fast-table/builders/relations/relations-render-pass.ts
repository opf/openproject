import {PrimaryRenderPass, RenderedRow, SecondaryRenderPass} from '../primary-render-pass';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableRelationColumnsService} from '../../state/wp-table-relation-columns.service';
import {$injectFields} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {relationGroupClass, RelationRowBuilder} from './relation-row-builder';
import {rowId} from '../../helpers/wp-table-row-helpers';
import {WorkPackageRelationsService} from '../../../wp-relations/wp-relations.service';

export class RelationsRenderPass implements SecondaryRenderPass {
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
    rendered.forEach((row:RenderedRow, position:number) => {

      // We only care for rows that are natural work packages
      if (!(row.isWorkPackage && row.belongsTo)) {
        return;
      }

      // If the work package has no relations, ignore
      const fromId = row.belongsTo.id;
      const state = this.wpRelations.getRelationsForWorkPackage(fromId);
      if (!state.hasValue() || _.size(state.value!) === 0) {
        return;
      }

      this.wpTableRelationColumns.relationsToExtendFor(row.belongsTo,
        state.value!,
        (relation, type) => {

          // Build each relation row (currently sorted by order defined in API)
          const [relationRow,] = this.relationRowBuilder.buildEmptyRelationRow(row.belongsTo!,
            relation,
            type);

          // Augment any data for the belonging work package row to it
          this.tablePass.augmentSecondaryElement(relationRow, row);

          // Insert next to the work package row
          // If no relations exist until here, directly under the row
          // otherwise as the last element of the relations
          // Insert into table
          this.tablePass.spliceRow(
            relationRow,
            `#${rowId(fromId)},.${relationGroupClass(fromId)}`,
            {
              isWorkPackage: false,
              belongsTo: row.belongsTo,
              hidden: row.hidden
            }
          );
        });
    });
  }

  private get isApplicable() {
    return this.wpTableColumns.hasRelationColumns();
  }
}
