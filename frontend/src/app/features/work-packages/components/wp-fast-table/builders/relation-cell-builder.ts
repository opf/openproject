import { Injector } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  WorkPackageViewRelationColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageRelationsService } from '../../wp-relations/wp-relations.service';
import { QueryColumn, queryColumnTypes } from '../../wp-query/query-column';
import { tdClassName } from './cell-builder';

export const relationCellTdClassName = 'wp-table--relation-cell-td';
export const relationCellIndicatorClassName = 'wp-table--relation-indicator';

export class RelationCellbuilder {
  @LazyInject() states:States;

  @LazyInject() wpRelations:WorkPackageRelationsService;

  @LazyInject() wpTableRelationColumns:WorkPackageViewRelationColumnsService;

  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResource, column:QueryColumn) {
    const td = document.createElement('td');
    td.classList.add(tdClassName, relationCellTdClassName, column.id);
    td.dataset.columnId = column.id;

    // Get current expansion and value state
    const expanded = this.wpTableRelationColumns.getExpandFor(workPackage.id!) === column.id;
    const relationState = this.wpRelations.state(workPackage.id!).value;

    let count:number;

    if (column._type === queryColumnTypes.RELATION_CHILD) {
      count = workPackage.children?.length || 0;
    } else {
      const relations = this.wpTableRelationColumns.relationsForColumn(
        workPackage,
        relationState,
        column,
      );
      count = relations.length;
    }

    const indicator = this.renderIndicator();
    const badge = this.renderBadge(count);

    if (expanded) {
      td.classList.add('-expanded');
    }

    if (count > 0) {
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

  private renderBadge(count:number) {
    const badge = document.createElement('span');
    badge.classList.add('wp-table--relation-count');

    badge.textContent = count.toString();
    badge.classList.add('badge');

    return badge;
  }
}
