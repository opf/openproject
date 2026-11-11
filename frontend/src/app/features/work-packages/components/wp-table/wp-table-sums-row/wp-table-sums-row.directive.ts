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

import { AfterViewInit, Directive, DestroyRef, ElementRef, Injector, input, inject, effect, signal, computed, untracked } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { States } from 'core-app/core/states/states.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { combineLatest } from 'rxjs';
import { GroupSumsBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/group-sums-builder';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { totalsRowKey } from 'core-app/features/work-packages/components/wp-fast-table/row-keys';

@Directive({
  // eslint-disable-next-line @angular-eslint/directive-selector
  selector: '[wpTableSumsRow]',
  host: {
    '[class.-hidden]': 'isHidden()',
  },
  standalone: false,
})
export class WorkPackageTableSumsRowController implements AfterViewInit {
  readonly injector = inject(Injector);
  readonly elementRef = inject<ElementRef<HTMLTableRowElement>>(ElementRef);
  readonly querySpace = inject(IsolatedQuerySpace);
  readonly states = inject(States);
  readonly schemaCache = inject(SchemaCacheService);
  readonly wpTableColumns = inject(WorkPackageViewColumnsService);
  readonly wpTableSums = inject(WorkPackageViewSumService);
  readonly I18n = inject(I18nService);

  private readonly destroyRef = inject(DestroyRef);

  // eslint-disable-next-line @angular-eslint/no-input-rename
  readonly workPackageTable = input<WorkPackageTable>(undefined, { alias: 'wpTableSumsRow-table' });

  private readonly viewReady = signal(false);

  private readonly sourceState = toSignal(combineLatest({
    columns: this.wpTableColumns.live$(),
    sum: this.wpTableSums.live$(),
    results: this.querySpace.results.values$(),
  }));

  readonly isHidden = computed(() => !this.workPackageTable() || !this.sourceState()?.sum);

  private initializedTable?:WorkPackageTable;

  private text:{ sum:string };

  private element:HTMLTableRowElement;

  constructor() {
    this.text = { sum: this.I18n.t('js.label_total_sum') };

    effect((onCleanup) => {
      const table = this.workPackageTable();
      const state = this.sourceState();
      if (!this.viewReady() || !table || table.destroyed || this.destroyRef.destroyed) return;
      let current = true;
      onCleanup(() => { current = false; });

      untracked(() => {
        const sum = state?.sum;
        const resource = state?.results;
        if (this.initializedTable !== table || (!sum && this.element.hasChildNodes())) {
          this.initializedTable = table;
          table.mutate(new Set([totalsRowKey]), () => {
            if (!sum) this.clear();
          });
        }
        if (sum && resource?.sumsSchema) {
          void this.schemaCache.ensureLoaded(resource.sumsSchema.href!).then(() => {
            if (!current || table.destroyed || this.destroyRef.destroyed
              || this.workPackageTable() !== table || this.sourceState() !== state) return;
            table.mutate(new Set([totalsRowKey]), () => this.refresh(resource, table));
          });
        } else if (this.element.hasChildNodes()) {
          table.mutate(new Set([totalsRowKey]), () => this.clear());
        }
      });
    });
  }

  ngAfterViewInit():void {
    this.element = this.elementRef.nativeElement;
    this.viewReady.set(true);
  }

  private clear() {
    this.element.innerHTML = '';
  }

  private refresh(resource:WorkPackageCollectionResource, table:WorkPackageTable) {
    this.clear();
    const builder = new GroupSumsBuilder(this.injector, table);
    builder.text = this.text;
    builder.renderColumns(resource.totalSums!, this.element, 'total');
  }
}
