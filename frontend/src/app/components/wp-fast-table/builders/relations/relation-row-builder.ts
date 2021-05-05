import { Injector } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { RelationResource } from 'core-app/modules/hal/resources/relation-resource';
import { States } from '../../../states.service';
import { isRelationColumn, QueryColumn } from '../../../wp-query/query-column';
import { WorkPackageTable } from '../../wp-fast-table';
import { tdClassName } from '../cell-builder';
import { commonRowClassName, SingleRowBuilder, tableRowClassName } from '../rows/single-row-builder';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { RelationColumnType } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-relation-columns.service";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

export function relationGroupClass(workPackageId:string) {
  return `__relations-expanded-from-${workPackageId}`;
}

export function relationIdentifier(targetId:string, workPackageId:string) {
  return `wp-relation-row-${workPackageId}-to-${targetId}`;
}

export const relationCellClassName = 'wp-table--relation-cell-td';

export class RelationRowBuilder extends SingleRowBuilder {

  @InjectField() public states:States;
  @InjectField() public I18n:I18nService;

  constructor(public readonly injector:Injector,
              protected workPackageTable:WorkPackageTable) {

    super(injector, workPackageTable);
  }

  /**
   * For additional relation rows, we don't want to render an expandable relation cell,
   * but instead we render the relation label.
   * @param workPackage
   * @param column
   * @return {any}
   */
  public buildCell(workPackage:WorkPackageResource, column:QueryColumn):HTMLElement|null {

    // handle relation types
    if (isRelationColumn(column)) {
      return this.emptyRelationCell(column);
    }

    return super.buildCell(workPackage, column);
  }

  /**
   * Build the columns on the given empty row
   */
  public buildEmptyRelationRow(from:WorkPackageResource, relation:RelationResource, type:RelationColumnType):[HTMLElement, WorkPackageResource] {
    const denormalized = relation.denormalized(from);

    const to = this.states.workPackages.get(denormalized.targetId).value!;

    // Let the primary row builder build the row
    const row = this.createEmptyRelationRow(from, to);
    const [tr, _] = super.buildEmptyRow(to, row);

    return [tr, to];
  }

  /**
   * Create an empty unattached row element for the given work package
   * @param workPackage
   * @returns {any}
   */
  public createEmptyRelationRow(from:WorkPackageResource, to:WorkPackageResource) {
    const identifier = this.relationClassIdentifier(from, to);
    const tr = document.createElement('tr');
    tr.dataset['workPackageId'] = to.id!;
    tr.dataset['classIdentifier'] = identifier;

    tr.classList.add(
      commonRowClassName, tableRowClassName, 'issue',
      `wp-table--relations-aditional-row`,
      identifier,
      `${identifier}-table`,
      relationGroupClass(from.id!)
    );

    return tr;
  }

  public relationClassIdentifier(from:WorkPackageResource, to:WorkPackageResource) {
    return relationIdentifier(to.id!, from.id!);
  }

  /**
   *
   * @param from
   * @param denormalized
   * @param type
   */
  public appendRelationLabel(jRow:JQuery, from:WorkPackageResource, relation:RelationResource, columnId:string, type:RelationColumnType) {
    const denormalized = relation.denormalized(from);
    let typeLabel = '';

    // Add the relation label if this is a "Relations for <WP Type>" column
    if (type === 'toType') {
      typeLabel = this.I18n.t(`js.relation_labels.${denormalized.reverseRelationType}`);
    }
    // Add the WP type label if this is a "<Relation Type> Relations" column
    if (type === 'ofType') {
      const wp = this.states.workPackages.get(denormalized.target.id!).value!;
      typeLabel = wp.type.name;
    }

    const relationLabel = document.createElement('span');
    relationLabel.classList.add('relation-row--type-label');
    relationLabel.textContent = typeLabel;

    const textNode = document.createTextNode(denormalized.target.name);

    jRow.find(`.${relationCellClassName}`).empty();
    jRow.find(`.${relationCellClassName}.${columnId}`).append(relationLabel);
  }

  protected emptyRelationCell(column:QueryColumn) {
    const cell = document.createElement('td');
    cell.classList.add(relationCellClassName, tdClassName, column.id);

    return cell;
  }
}
