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

import { AfterViewInit, Directive, DestroyRef, ElementRef, Injector, Input, inject } from '@angular/core';
import { switchMap, tap } from 'rxjs/operators';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { States } from 'core-app/core/states/states.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { combineLatest, ReplaySubject } from 'rxjs';
import { GroupSumsBuilder } from 'core-app/features/work-packages/components/wp-fast-table/builders/modes/grouped/group-sums-builder';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { totalsRowKey } from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/keyboard/navigable-rows';
import { keyboardNavigationEnabled } from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/keyboard/roving-tabindex';
import { paintRowRole, paintSectionExposure } from 'core-app/features/work-packages/components/wp-fast-table/semantics/treegrid-semantics';

@Directive({
  // eslint-disable-next-line @angular-eslint/directive-selector
  selector: '[wpTableSumsRow]',
  host: {
    '[class.-hidden]': 'isHidden',
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

  private readonly tables = new ReplaySubject<WorkPackageTable>(1);

  private currentTable:WorkPackageTable;

  // eslint-disable-next-line @angular-eslint/no-input-rename
  @Input('wpTableSumsRow-table')
  set workPackageTable(table:WorkPackageTable) {
    this.currentTable = table;
    if (table) this.tables.next(table);
  }

  get workPackageTable():WorkPackageTable {
    return this.currentTable;
  }

  public isHidden = true;

  private text:{ sum:string };

  private element:HTMLTableRowElement;

  private groupSumsBuilder:GroupSumsBuilder;

  constructor() {
    const I18n = this.I18n;

    this.text = {
      sum: I18n.t('js.label_total_sum'),
    };
  }

  ngAfterViewInit():void {
    this.element = this.elementRef.nativeElement;

    this.tables
      .pipe(
        tap((table) => this.reconcileSemantics(table)),
        switchMap((table) => combineLatest([
          this.wpTableColumns.live$(),
          this.wpTableSums.live$(),
          this.querySpace.results.values$(),
        ]).pipe(takeUntilDestroyed(table.destroyRef))),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe(([columns, sum, resource]) => {
        const table = this.workPackageTable;
        if (!table || table.destroyed || this.destroyRef.destroyed) return;
        this.isHidden = !sum;
        if (sum && resource.sumsSchema) {
          void this.schemaCache
            .ensureLoaded(resource.sumsSchema.href!)
            .then(() => {
              if (table.destroyed || this.destroyRef.destroyed || this.workPackageTable !== table || !this.wpTableSums.isEnabled) return;
              table.keyboardNavigation?.captureOwnership();
              this.refresh(columns, resource);
              this.paintSemantics(table);
              table.notifyRowsRefreshed(totalsRowKey);
            });
        } else if (this.element.hasChildNodes()) {
          table.keyboardNavigation?.captureOwnership();
          this.clear();
          this.paintSemantics(table);
          table.notifyRowsRefreshed(totalsRowKey);
        }
      });
  }

  private reconcileSemantics(table:WorkPackageTable) {
    if (this.paintSemantics(table)) table.rowPositions?.paint();
  }

  private paintSemantics(table:WorkPackageTable):boolean {
    if (table.destroyed || !keyboardNavigationEnabled(table.configuration)) return false;

    if (this.isHidden || this.element.cells.length === 0) {
      this.element.setAttribute('aria-hidden', 'true');
    } else {
      this.element.removeAttribute('aria-hidden');
    }
    paintRowRole(this.element, 1);
    paintSectionExposure(this.element.parentElement as HTMLTableSectionElement);
    return true;
  }

  private clear() {
    this.element.innerHTML = '';
  }

  private refresh(columns:QueryColumn[], resource:WorkPackageCollectionResource) {
    this.clear();
    this.render(columns, resource);
  }

  private render(columns:QueryColumn[], resource:WorkPackageCollectionResource) {
    this.groupSumsBuilder = new GroupSumsBuilder(this.injector, this.workPackageTable);
    this.groupSumsBuilder.text = this.text;
    this.groupSumsBuilder.renderColumns(resource.totalSums!, this.element, 'total');
  }
}
