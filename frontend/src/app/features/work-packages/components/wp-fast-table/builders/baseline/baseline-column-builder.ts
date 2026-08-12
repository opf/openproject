//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
