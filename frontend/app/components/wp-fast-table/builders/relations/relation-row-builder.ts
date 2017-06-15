import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {commonRowClassName, rowClassName, SingleRowBuilder} from '../rows/single-row-builder';
import {
  DenormalizedRelationData,
  RelationResource
} from '../../../api/api-v3/hal-resources/relation-resource.service';
import {UiStateLinkBuilder} from '../ui-state-link-builder';
import {QueryColumn} from '../../../wp-query/query-column';
import {$injectFields} from '../../../angular/angular-injector-bridge.functions';
import {RelationColumnType} from '../../state/wp-table-relation-columns.service';
import {States} from '../../../states.service';

export function relationGroupClass(workPackageId:string) {
  return `__relations-expanded-from-${workPackageId}`;
}

export const internalDetailsColumn = {
  id: '__internal-detailsLink'
} as QueryColumn;

export class RelationRowBuilder extends SingleRowBuilder {
  public uiStateBuilder:UiStateLinkBuilder;
  public states:States;
  public I18n:op.I18n;

  constructor(protected workPackageTable:WorkPackageTable) {
    super(workPackageTable);
    this.uiStateBuilder = new UiStateLinkBuilder();
    $injectFields(this, 'I18n', 'states');
  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmptyRelationRow(from:WorkPackageResourceInterface, relation:RelationResource, type:RelationColumnType):[HTMLElement, boolean] {
    const denormalized = relation.denormalized(from);
    const tr = this.createEmptyRelationRow(from, denormalized);
    const columns = this.wpTableColumns.getColumns();

    // Set available information for ID and subject column
    // and print hierarchy indicator at subject field.
    columns.forEach((column:QueryColumn) => {
      const td = document.createElement('td');

      if (column.id === 'subject') {
        this.buildRelationLabel(td, from, denormalized, type);
      }

      if (column.id === 'id') {
        const link = this.uiStateBuilder.linkToShow(
          denormalized.target.id,
          denormalized.target.name,
          denormalized.target.id
        );

        td.appendChild(link);
        td.classList.add('relation-row--id-cell');
      }

      tr.appendChild(td);
    });

    // Append details icon
    const td = document.createElement('td');
    tr.appendChild(td);

    return [tr, false];
  }

  /**
   * Create an empty unattached row element for the given work package
   * @param workPackage
   * @returns {any}
   */
  public createEmptyRelationRow(from:WorkPackageResource, relation:DenormalizedRelationData) {
    let tr = document.createElement('tr');
    tr.dataset['relatedWorkPackageId'] = from.id;
    tr.classList.add(
      rowClassName, commonRowClassName, 'issue', '-no-highlighting',
      `wp-table--relations-aditional-row`, relationGroupClass(from.id)
    );

    return tr;
  }

  private buildRelationLabel(cell:HTMLElement, from:WorkPackageResource, denormalized:DenormalizedRelationData, type:RelationColumnType) {
    let typeLabel;

    // Add the relation label if this is a "Relations for <WP Type>" column
    if (type === 'toType') {
      typeLabel = this.I18n.t(`js.relation_labels.${denormalized.relationType}`);
    }
    // Add the WP type label if this is a "<Relation Type> Relations" column
    if (type === 'ofType') {
      const wp = this.states.workPackages.get(denormalized.target.id).value!;
      typeLabel = wp.type.name;
    }

    const relationLabel = document.createElement('span');
    relationLabel.classList.add('relation-row--type-label');
    relationLabel.textContent = typeLabel;

    const textNode = document.createTextNode(denormalized.target.name);
    cell.appendChild(relationLabel);
    cell.appendChild(textNode);
  }
}
