import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {commonRowClassName, rowClassName, SingleRowBuilder} from '../rows/single-row-builder';
import {RelationResource} from '../../../api/api-v3/hal-resources/relation-resource.service';
import {UiStateLinkBuilder} from '../ui-state-link-builder';
import {QueryColumn} from '../../../wp-query/query-column';

export function relationGroupClass(workPackageId:string) {
  return `__relations-expanded-from-${workPackageId}`;
}

export const internalDetailsColumn = {
  id: '__internal-detailsLink'
} as QueryColumn;

export class RelationRowBuilder extends SingleRowBuilder {
  public uiStateBuilder:UiStateLinkBuilder;

  constructor(protected workPackageTable:WorkPackageTable) {
    super(workPackageTable);

    this.uiStateBuilder = new UiStateLinkBuilder();
  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmptyRelationRow(from:WorkPackageResourceInterface,  relation:RelationResource):[HTMLElement, boolean] {
    const denormalized = relation.denormalized(from);
    const tr = this.createEmptyRelationRow(from, denormalized);
    const columns = this.wpTableColumns.getColumns();

    // Set available information for ID and subject column
    // and print hierarchy indicator at subject field.
    columns.forEach((column:QueryColumn) => {
      const td = document.createElement('td');

      if (column.id === 'subject') {
        const textNode = document.createTextNode(`(${denormalized.relationType}) ${denormalized.target.name}`);
        td.appendChild(textNode);
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
  public createEmptyRelationRow(from:WorkPackageResource, relation:{ target:WorkPackageResource }) {
    let tr = document.createElement('tr');
    tr.dataset['relatedworkPackageId'] = from.id;
    tr.dataset['workPackageId'] = relation.target.id;
    tr.classList.add(
      rowClassName, commonRowClassName, 'issue',
      `wp-table--relations-aditional-row`, relationGroupClass(from.id)
    );

    return tr;
  }
}
