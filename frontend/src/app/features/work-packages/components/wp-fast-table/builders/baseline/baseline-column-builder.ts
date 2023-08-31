import { Injector } from '@angular/core';
import {
  WorkPackageResource,
} from 'core-app/features/hal/resources/work-package-resource';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { tdClassName } from 'core-app/features/work-packages/components/wp-fast-table/builders/cell-builder';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { opIconElement } from 'core-app/shared/helpers/op-icon-builder';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { getBaselineState } from '../../../wp-baseline/baseline-helpers';

export const baselineCellName = 'op-table-baseline--column-cell';

export class BaselineColumnBuilder {
  @InjectField() states:States;

  @InjectField() wpTableBaseline:WorkPackageViewBaselineService;

  @InjectField() schemaCache:SchemaCacheService;

  @InjectField() I18n:I18nService;

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
      const icon = opIconElement('spot-icon', 'spot-icon_1', 'spot-icon_flex', 'spot-icon_arrow-in', 'op-table-baseline--icon-added');
      icon.title = this.I18n.t('js.work_packages.baseline.addition_label');
      return icon;
    }

    if (state === 'removed') {
      const icon = opIconElement('spot-icon', 'spot-icon_1', 'spot-icon_flex', 'spot-icon_arrow-out', 'op-table-baseline--icon-removed');
      icon.title = this.I18n.t('js.work_packages.baseline.removal_label');
      return icon;
    }

    if (state === 'updated') {
      const icon = opIconElement('spot-icon', 'spot-icon_1', 'spot-icon_flex', 'spot-icon_delta-triangle', 'op-table-baseline--icon-changed');
      icon.title = this.I18n.t('js.work_packages.baseline.modification_label');
      return icon;
    }

    return null;
  }
}
