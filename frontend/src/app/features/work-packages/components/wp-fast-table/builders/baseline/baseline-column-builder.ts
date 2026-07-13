import { Injector } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { tdClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/cell-builder';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { octiconElement } from 'core-app/shared/helpers/op-icon-builder';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { getBaselineState } from '../../../wp-baseline/baseline-helpers';
import {
  opArrowInIconData,
  opTriangleDeltaIconData,
  replyIconData,
} from '@openproject/octicons-angular';

export const baselineCellName = 'op-table-baseline--column-cell';

export class BaselineColumnBuilder {
  @LazyInject() states:States;

  @LazyInject() wpTableBaseline:WorkPackageViewBaselineService;

  @LazyInject() schemaCache:SchemaCacheService;

  @LazyInject() I18n:I18nService;

  constructor(public readonly injector:Injector) {
  }

  public build(workPackage:WorkPackageResource, column:QueryColumn) {
    const td = document.createElement('td');
    td.classList.add(tdClassName, baselineCellName, column.id);
    td.dataset.columnId = column.id;

    const timestamps = workPackage.attributesByTimestamp || [];

    // Nothing to render if we don't have a comparison
    if (timestamps.length <= 1) {
      return td;
    }

    // Check if added
    const icon = this.changeIcon(workPackage);
    if (icon) {
      td.appendChild(icon);
    }

    return td;
  }

  private changeIcon(
    workPackage:WorkPackageResource,
  ):HTMLElement|null {
    const state = getBaselineState(workPackage, this.schemaCache);
    if (state === 'added') {
      return octiconElement(opArrowInIconData,
        'small',
        'op-table-baseline--icon-added',
        this.I18n.t('js.work_packages.baseline.addition_label'));
    }

    if (state === 'removed') {
      return octiconElement(replyIconData,
        'small',
        'op-table-baseline--icon-removed',
        this.I18n.t('js.work_packages.baseline.removal_label'));
    }

    if (state === 'updated') {
      return octiconElement(opTriangleDeltaIconData,
        'small',
        'op-table-baseline--icon-changed',
        this.I18n.t('js.work_packages.baseline.modification_label'));
    }

    return null;
  }
}
