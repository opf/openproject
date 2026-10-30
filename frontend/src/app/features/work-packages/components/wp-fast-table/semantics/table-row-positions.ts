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
import type { GroupObject, WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { groupOccurrenceKey, placeholderOccurrenceKey, wpOccurrenceKey, type RenderDraft } from '../rendered-occurrence-ledger';
import type { WorkPackageTable } from '../wp-fast-table';
import { isEmptyResultsRow, isExposedRow, isInlineCreateRow, isTotalsRow } from '../helpers/structural-rows';
import { setOrRemove } from './treegrid-semantics';
import { bodyRowPositions, draftAgrees, type BodyRowPositions, type PositionGroup } from './body-row-positions';

export interface CapturedRowPositions {
  /** `page` numbers rows from the page's first query rank and withholds the total. */
  readonly kind:'query'|'page';
  readonly source:WorkPackageCollectionResource;
  readonly body:BodyRowPositions;
}

// Group counts are computed from the unscoped query results, so only the primary collections carry trustworthy aggregates.
const UNSCOPED_COLLECTION_HREF = /\/api\/v3\/(?:(?:projects|workspaces)\/[^/]+\/)?work_packages(?:\?|$)/;

type ProjectedRowKind = 'ledger'|'skipped'|'empty'|'totals'|'create'|'foreign';

export class TableRowPositions {
  @LazyInject(WorkPackageViewHierarchiesService) private readonly hierarchies:WorkPackageViewHierarchiesService;

  @LazyInject(WorkPackageViewColumnsService) private readonly columns:WorkPackageViewColumnsService;

  @LazyInject(WorkPackageViewRelationColumnsService) private readonly relationColumns:WorkPackageViewRelationColumnsService;

  @LazyInject(WorkPackageViewBaselineService) private readonly baseline:WorkPackageViewBaselineService;

  public readonly injector:Injector = this.table.injector;

  private snapshot:CapturedRowPositions|null = null;

  constructor(private readonly table:WorkPackageTable) {}

  public capture(draft:RenderDraft):CapturedRowPositions|null {
    const source = this.table.querySpace.results.value;
    if (!source || this.withdrawnByMode() || !this.matchesRenderedRows(source)) return null;

    const groups = this.table.querySpace.groups.value ?? [];
    if (this.hierarchies.isEnabled) return groups.length > 0 ? null : this.capturePage(source, draft);
    if (groups.length > 0 && !this.trustsGroupedAggregates(source, groups)) return null;

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
    if (!body) return null;

    const rows = draft.occurrences
      .filter((occurrence) => occurrence.key !== placeholderOccurrenceKey())
      .map((occurrence) => ({ key: occurrence.key, member: occurrence.workPackageId !== null }));
    return draftAgrees(body, rows, positionGroups) ? { kind: 'query', source, body } : null;
  }

  public commit(snapshot:CapturedRowPositions|null):void {
    this.snapshot = snapshot;
  }

  /** Producers call this synchronously after every imperative row move or structural change, so no frame exposes a stale index. */
  public paint():void {
    if (this.table.destroyed) return;
    const element = this.table.tbody.closest('table');
    if (!element) return;
    const rows = Array.from(element.rows);
    const projection = this.project(element, rows);
    setOrRemove(element, 'aria-rowcount', projection ? String(projection.count ?? -1) : null);
    rows.forEach((row) => {
      const position = projection?.indices.get(row);
      setOrRemove(row, 'aria-rowindex', position === undefined ? null : String(position));
    });
  }

  /** Contextual ancestors make the query-wide total unknowable, so rendered rows count from the page's first rank. */
  private capturePage(source:WorkPackageCollectionResource, draft:RenderDraft):CapturedRowPositions|null {
    const { offset, pageSize } = source;
    const firstRank = (offset - 1) * pageSize;
    if (!Number.isSafeInteger(offset) || offset < 1 || !Number.isSafeInteger(pageSize) || pageSize < 1
      || !Number.isSafeInteger(firstRank)) {
      return null;
    }
    const keys = draft.occurrences
      .filter((occurrence) => occurrence.key !== placeholderOccurrenceKey())
      .map((occurrence) => occurrence.key);
    const ordinals = new Map(keys.map((key, index) => [key, firstRank + index + 1]));
    if (ordinals.size !== keys.length) return null;
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

  private trustsGroupedAggregates(source:WorkPackageCollectionResource, groups:GroupObject[]):boolean {
    return source.groups === groups
      && !this.baseline.isActive()
      && UNSCOPED_COLLECTION_HREF.test(source.href ?? '');
  }

  private project(element:HTMLTableElement, rows:HTMLTableRowElement[]) {
    const snapshot = this.snapshot;
    if (!snapshot || snapshot.source !== this.table.querySpace.results.value) return null;
    const { body } = snapshot;
    const header = element.tHead?.rows;
    if (header?.length !== 1) return null;

    const indices = new Map<HTMLTableRowElement, number>([[header[0], 1]]);
    const trailers:HTMLTableRowElement[] = [];
    const seen = new Set<ProjectedRowKind>();
    let emptySurrogate:HTMLTableRowElement|null = null;
    for (const row of rows) {
      if (row === header[0]) continue;
      const kind = this.classify(row);
      if (kind === 'skipped') continue;
      if (kind === 'ledger') {
        const ordinal = body.ordinals.get(this.table.ledger.byElement(row)!.key);
        if (ordinal === undefined) return null;
        indices.set(row, ordinal + 1);
      } else if (kind === 'empty') {
        if (body.count !== 0 || emptySurrogate) return null;
        emptySurrogate = row;
      } else if (kind === 'totals' || kind === 'create') {
        if (seen.has(kind)) return null;
        seen.add(kind);
        trailers.push(row);
      } else {
        return null;
      }
    }

    let count = 1 + body.count;
    for (const row of [...(emptySurrogate ? [emptySurrogate] : []), ...trailers]) {
      count += 1;
      indices.set(row, count);
    }
    if (!Number.isSafeInteger(count)) return null;

    let previous = 0;
    for (const row of rows) {
      const position = indices.get(row);
      if (position === undefined) continue;
      if (!Number.isSafeInteger(position) || position <= previous || position > count) return null;
      previous = position;
    }
    return { count: snapshot.kind === 'query' ? count : null, indices };
  }

  private classify(row:HTMLTableRowElement):ProjectedRowKind {
    const occurrence = this.table.ledger.byElement(row);
    if (occurrence) return occurrence.key === placeholderOccurrenceKey() ? 'skipped' : 'ledger';
    if (!isExposedRow(row)) return 'skipped';
    if (isEmptyResultsRow(row)) return 'empty';
    if (isTotalsRow(this.table, row)) return row.cells.length === 0 ? 'skipped' : 'totals';
    if (isInlineCreateRow(row)) return row.cells.length === 0 ? 'skipped' : 'create';
    return 'foreign';
  }
}
