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
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import type { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { groupOccurrenceKey, placeholderOccurrenceKey, wpOccurrenceKey, type RenderDraft } from '../rendered-occurrence-ledger';
import type { WorkPackageTable } from '../wp-fast-table';
import { classifyRow } from '../helpers/structural-rows';
import { setOrRemove } from './treegrid-semantics';
import { bodyRowPositions, draftAgrees, type BodyRowPositions, type PositionGroup } from './body-row-positions';

export interface CapturedRowPositions {
  /** `page` numbers rows from the page's first query rank and withholds the total. */
  readonly kind:'query'|'page';
  readonly source:WorkPackageCollectionResource;
  readonly body:BodyRowPositions;
}

// Group counts are computed from the unscoped query results, so grouped positions trust only the query collections:
// `/api/v3/work_packages` and `/api/v3/workspaces/:id/work_packages` (the self links
// `WorkPackageCollectionFromQueryService` emits), plus the `projects/:id` alias of the latter.
// A new collection route that renders this table must be added here, or its grouped views withdraw positions.
const UNSCOPED_COLLECTION_HREF = /\/api\/v3\/(?:(?:projects|workspaces)\/[^/]+\/)?work_packages(?:\?|$)/;

export class TableRowPositions {
  @LazyInject(WorkPackageViewHierarchiesService) private readonly hierarchies:WorkPackageViewHierarchiesService;

  @LazyInject(WorkPackageViewColumnsService) private readonly columns:WorkPackageViewColumnsService;

  @LazyInject(WorkPackageViewRelationColumnsService) private readonly relationColumns:WorkPackageViewRelationColumnsService;

  @LazyInject(WorkPackageViewBaselineService) private readonly baseline:WorkPackageViewBaselineService;

  public readonly injector:Injector = this.table.injector;

  private snapshot:CapturedRowPositions|null = null;

  private foreignRowReported = false;

  constructor(private readonly table:WorkPackageTable) {}

  public capture(draft:RenderDraft):CapturedRowPositions|null {
    const source = this.table.querySpace.results.value;
    if (!source) return null;
    if (this.withdrawnByMode()) return this.notOffered('expanded relation columns');
    if (!this.matchesRenderedRows(source)) return this.notOffered('rows await a matching collection');

    const groups = this.table.querySpace.groups.value ?? [];
    if (this.hierarchies.isEnabled) return groups.length > 0 ? this.notOffered('grouped hierarchy') : this.capturePage(source, draft);
    if (groups.length > 0) {
      if (this.baseline.isActive()) return this.notOffered('grouped baseline');
      if (source.groups !== groups) return this.withdraw('group objects differ from collection');
      if (!UNSCOPED_COLLECTION_HREF.test(source.href ?? '')) return this.withdraw('untrusted collection href');
    }

    const positionGroups:PositionGroup[] = groups.map((group, index) => ({
      headerKey: groupOccurrenceKey(index, 'header'),
      sumsKey: groupOccurrenceKey(index, 'sums'),
      count: group.count,
      hasSums: !!group.sums,
    }));
    const body = bodyRowPositions({
      pageNumber: source.offset,
      pageSize: source.pageSize,
      total: source.total,
      primaryKeys: this.table.originalRows.map(wpOccurrenceKey),
      groups: positionGroups,
    });
    if (!body) return this.withdraw('inconsistent collection counts');

    const rows = draft.occurrences
      .filter((occurrence) => occurrence.key !== placeholderOccurrenceKey())
      .map((occurrence) => ({ key: occurrence.key, member: occurrence.workPackageId !== null }));
    return draftAgrees(body, rows, positionGroups) ? { kind: 'query', source, body } : this.withdraw('rows disagree with collection');
  }

  public commit(snapshot:CapturedRowPositions|null):void {
    this.snapshot = snapshot;
  }

  /** Producers call this synchronously after every imperative row move or structural change, so no frame exposes a stale index. */
  public paint():void {
    if (this.table.destroyed) return;
    const element = this.table.tbody.closest('table');
    if (!element || (!this.currentSnapshot() && !element.hasAttribute('aria-rowcount'))) return;
    const rows = Array.from(element.rows);
    const projection = this.project(element, rows);
    setOrRemove(element, 'aria-rowcount', projection ? String(projection.count ?? -1) : null);
    rows.forEach((row) => {
      const position = projection?.indices.get(row);
      setOrRemove(row, 'aria-rowindex', position === undefined ? null : String(position));
    });
  }

  /** A refreshed row replaces its predecessor in place under the same occurrence key, so it inherits that row's index. */
  public carry(previous:HTMLTableRowElement, replacement:HTMLTableRowElement):void {
    if (this.table.destroyed) return;
    if (!this.currentSnapshot()) {
      this.paint();
      return;
    }
    setOrRemove(replacement, 'aria-rowindex', previous.getAttribute('aria-rowindex'));
  }

  /** Contextual ancestors make the query-wide total unknowable, so rendered rows count from the page's first rank. */
  private capturePage(source:WorkPackageCollectionResource, draft:RenderDraft):CapturedRowPositions|null {
    const { offset, pageSize } = source;
    const firstRank = (offset - 1) * pageSize;
    if (!Number.isSafeInteger(offset) || offset < 1 || !Number.isSafeInteger(pageSize) || pageSize < 1
      || !Number.isSafeInteger(firstRank)) {
      return this.withdraw('invalid pagination');
    }
    const keys = draft.occurrences
      .filter((occurrence) => occurrence.key !== placeholderOccurrenceKey())
      .map((occurrence) => occurrence.key);
    const ordinals = new Map(keys.map((key, index) => [key, firstRank + index + 1]));
    if (ordinals.size !== keys.length) return this.withdraw('duplicate occurrence keys');
    return { kind: 'page', source, body: { count: firstRank + keys.length, ordinals } };
  }

  private withdrawnByMode():boolean {
    return (this.columns.hasRelationColumns() || this.columns.hasChildRelationsColumn())
      && Object.keys(this.relationColumns.current).length > 0;
  }

  private matchesRenderedRows(source:WorkPackageCollectionResource):boolean {
    const { originalRows } = this.table;
    return source.count === originalRows.length
      && source.elements.length === originalRows.length
      && source.elements.every((wp, index) => wp.id === originalRows[index]);
  }

  private project(element:HTMLTableElement, rows:HTMLTableRowElement[]) {
    if (!this.snapshot) return null;
    const snapshot = this.currentSnapshot();
    if (!snapshot) return this.notOffered('collection changed before render');
    const { body } = snapshot;
    const header = element.tHead?.rows;
    if (header?.length !== 1) return this.withdraw('header rows');

    const indices = new Map<HTMLTableRowElement, number>([[header[0], 1]]);
    const trailers:HTMLTableRowElement[] = [];
    const seen = new Set<'totals'|'create'>();
    let emptySurrogate:HTMLTableRowElement|null = null;
    for (const row of rows) {
      if (row === header[0]) continue;
      const kind = classifyRow(this.table, row);
      if (kind === 'foreign') {
        this.reportForeignRow();
        return this.withdraw('foreign row');
      }
      if (kind === 'placeholder' || kind === 'unexposed') continue;
      if (kind === 'empty') {
        if (body.count !== 0 || emptySurrogate) return this.withdraw('unexpected empty-results row');
        emptySurrogate = row;
      } else if (kind === 'totals' || kind === 'create') {
        if (row.cells.length === 0) continue;
        if (seen.has(kind)) return this.withdraw(`duplicate ${kind} row`);
        seen.add(kind);
        trailers.push(row);
      } else {
        const ordinal = body.ordinals.get(this.table.ledger.byElement(row)!.key);
        if (ordinal === undefined) return this.withdraw('row outside the collection');
        indices.set(row, ordinal + 1);
      }
    }

    let count = 1 + body.count;
    for (const row of [...(emptySurrogate ? [emptySurrogate] : []), ...trailers]) {
      count += 1;
      indices.set(row, count);
    }
    if (!Number.isSafeInteger(count)) return this.withdraw('unsafe count');

    let previous = 0;
    for (const row of rows) {
      const position = indices.get(row);
      if (position === undefined) continue;
      if (!Number.isSafeInteger(position) || position <= previous || position > count) return this.withdraw('non-monotonic');
      previous = position;
    }
    return { count: snapshot.kind === 'query' ? count : null, indices };
  }

  private currentSnapshot():CapturedRowPositions|null {
    return this.snapshot?.source === this.table.querySpace.results.value ? this.snapshot : null;
  }

  private withdraw(inconsistency:string):null {
    debugLog(`Row positions withdrawn: ${inconsistency}`);
    return null;
  }

  private reportForeignRow():void {
    if (this.foreignRowReported) return;
    this.foreignRowReported = true;
    window.ErrorReporter.captureMessage('Row positions withdrawn: foreign row', 'warning');
  }

  private notOffered(mode:string):null {
    debugLog(`Row positions not offered: ${mode}`);
    return null;
  }
}
