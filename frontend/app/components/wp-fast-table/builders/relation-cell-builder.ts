import {WorkPackageResourceInterface} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageDisplayFieldService} from './../../wp-display/wp-display-field/wp-display-field.service';
import {$injectFields} from '../../angular/angular-injector-bridge.functions';
import {States} from '../../states.service';
import {tdClassName} from './cell-builder';
import {WorkPackageTableRelationColumnsService} from '../state/wp-table-relation-columns.service';
import {RelationResource} from '../../api/api-v3/hal-resources/relation-resource.service';
import {QueryColumn} from '../../wp-query/query-column';
import {WorkPackageRelationsService} from '../../wp-relations/wp-relations.service';

export const relationCellTdClassName = 'wp-table--relation-cell-td';
export const relationCellIndicatorClassName = 'wp-table--relation-indicator';

export class RelationCellbuilder {
  public states:States;
  public wpRelations:WorkPackageRelationsService;
  public wpTableRelationColumns:WorkPackageTableRelationColumnsService;

  public wpDisplayField:WorkPackageDisplayFieldService;

  constructor() {
    $injectFields(this, 'states', 'wpRelations', 'wpTableRelationColumns');
  }

  public build(workPackage:WorkPackageResourceInterface, column:QueryColumn) {
    const td = document.createElement('td');
    td.classList.add(tdClassName, relationCellTdClassName, column.id);
    td.dataset['columnId'] = column.id;

    // Get current expansion and value state
    const expanded = this.wpTableRelationColumns.getExpandFor(workPackage.id) === column.id;
    const relationState = this.wpRelations.state(workPackage.id).value;
    const relations = this.wpTableRelationColumns.relationsForColumn(workPackage,
      relationState,
      column);

    const indicator = this.renderIndicator();
    const badge = this.renderBadge(relations);

    if (expanded) {
      td.classList.add('-expanded');
    }

    if (relations.length > 0) {
      td.appendChild(badge);
      td.appendChild(indicator);
    }

    return td;
  }

  private renderIndicator() {
    const indicator = document.createElement('span')
    indicator.classList.add(relationCellIndicatorClassName);
    indicator.setAttribute('aria-hidden', 'true');
    indicator.setAttribute('tabindex', '0');

    return indicator;
  }

  private renderBadge(relations:RelationResource[]) {
    const badge = document.createElement('span');
    badge.classList.add('wp-table--relation-count');

    badge.textContent = '' + relations.length;
    badge.classList.add('badge', '-border-only');

    return badge;
  }
}

