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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import { PrimaryRenderPass } from 'core-app/features/work-packages/components/wp-fast-table/builders/primary-render-pass';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';

export class HighlightingRenderPass {
  @LazyInject() wpTableHighlighting:WorkPackageViewHighlightingService;

  @LazyInject() querySpace:IsolatedQuerySpace;

  constructor(public readonly injector:Injector,
    private table:WorkPackageTable,
    private tablePass:PrimaryRenderPass) {

  }

  public render() {
    // If highlighting is done inline in attributes, skip
    if (!this.isApplicable) {
      return;
    }

    this.tablePass.draft.occurrences.forEach((occurrence) => {
      if (occurrence.workPackage && occurrence.element) this.paintRow(occurrence.element, occurrence.workPackage);
    });
  }

  /** Replaces the row's background highlight with the one for the work package's highlighted attribute, if it has one. */
  public refreshRow(row:HTMLTableRowElement, workPackage:WorkPackageResource):void {
    if (!this.isApplicable) return;
    Array.from(row.classList)
      .filter((name) => name.startsWith('__hl_'))
      .forEach((name) => row.classList.remove(name));
    this.paintRow(row, workPackage);
  }

  private paintRow(row:HTMLTableRowElement, workPackage:WorkPackageResource):void {
    const highlightAttribute = this.wpTableHighlighting.current.mode;
    const property = workPackage[highlightAttribute] as HalResource|null|undefined;
    if (!property) return;
    row.classList.add(...Highlighting.backgroundClass(highlightAttribute, property.id!).split(' '));
  }

  private get isApplicable() {
    return !(this.wpTableHighlighting.isInline || this.wpTableHighlighting.isDisabled);
  }
}
