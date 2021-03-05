import { Injector } from '@angular/core';
import { States } from '../../states.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { tdClassName } from './cell-builder';
import { RelationResource } from 'core-app/modules/hal/resources/relation-resource';
import { QueryColumn } from '../../wp-query/query-column';
import { WorkPackageRelationsService } from '../../wp-relations/wp-relations.service';
import { WorkPackageViewRelationColumnsService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-relation-columns.service";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

export const relationCellTdClassName = 'wp-table--relation-cell-td';
export const relationCellIndicatorClassName = 'wp-table--relation-indicator';

export class RelationCellbuilder {

  @InjectField() states:States;
  @InjectField() wpRelations:WorkPackageRelationsService;
  @InjectField() wpTableRelationColumns:WorkPackageViewRelationColumnsService;

  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResource, column:QueryColumn) {
    const td = document.createElement('td');
    td.classList.add(tdClassName, relationCellTdClassName, column.id);
    td.dataset['columnId'] = column.id;

    // Get current expansion and value state
    const expanded = this.wpTableRelationColumns.getExpandFor(workPackage.id!) === column.id;
    const relationState = this.wpRelations.state(workPackage.id!).value;
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
    const indicator = document.createElement('span');
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

