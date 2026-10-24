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
import type { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { States } from 'core-app/core/states/states.service';
import { groupOccurrenceKey, placeholderOccurrenceKey, wpOccurrenceKey, type RenderDraft, type RenderedOccurrence } from '../rendered-occurrence-ledger';
import type { WorkPackageTable } from '../wp-fast-table';
import { isEmptyResultsRow, isExposedRow, isInlineCreateRow, isTotalsRow } from '../helpers/structural-rows';
import { bodyRowPositions, draftAgrees, hierarchyRowPositions, type BodyRowPositions, type PositionGroup } from './body-row-positions';

export interface CapturedRowPositions {
  readonly source:WorkPackageCollectionResource;
  readonly body:BodyRowPositions;
}

// Group counts are computed from the unscoped query results, so only the primary collections carry trustworthy aggregates.
const UNSCOPED_COLLECTION_HREF = /\/api\/v3\/(?:(?:projects|workspaces)\/[^/]+\/)?work_packages(?:\?|$)/;

type ProjectedRowKind = 'ledger'|'skipped'|'empty'|'totals'|'create'|'foreign';

export function describesRows(source:WorkPackageCollectionResource, rows:readonly string[]):boolean {
  return source.count === rows.length
    && source.elements.length === rows.length
    && source.elements.every((wp, index) => wp.id === rows[index]);
}

function setIfChanged(element:Element, name:string, value:string|null):void {
  if (value === null) {
    if (element.hasAttribute(name)) element.removeAttribute(name);
  } else if (element.getAttribute(name) !== value) {
    element.setAttribute(name, value);
  }
}

export class TableRowPositions {
  @LazyInject(WorkPackageViewHierarchiesService) private readonly hierarchies:WorkPackageViewHierarchiesService;

  @LazyInject(WorkPackageViewColumnsService) private readonly columns:WorkPackageViewColumnsService;

  @LazyInject(WorkPackageViewRelationColumnsService) private readonly relationColumns:WorkPackageViewRelationColumnsService;

  @LazyInject(WorkPackageViewBaselineService) private readonly baseline:WorkPackageViewBaselineService;

  @LazyInject(States) private readonly states:States;

  public readonly injector:Injector = this.table.injector;

  private snapshot:CapturedRowPositions|null = null;

  constructor(private readonly table:WorkPackageTable) {}

  public capture(draft:RenderDraft):CapturedRowPositions|null {
    const source = this.table.querySpace.results.value;
    if (!source || this.withdrawnByMode()) return null;
    if (!describesRows(source, this.table.originalRows)) return null;
    if (this.hierarchies.isEnabled) return this.captureHierarchy(source, draft);

    const groups = this.table.querySpace.groups.value ?? [];
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
    return draftAgrees(body, rows, positionGroups) ? { source, body } : null;
  }

  /** Re-derives the committed positions after a row re-rendered from a newer resource, withdrawing them if its ancestry moved. */
  public refreshed():void {
    if (this.snapshot) this.revalidate();
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
    setIfChanged(element, 'aria-rowcount', projection ? String(projection.count) : null);
    rows.forEach((row) => {
      const position = projection?.indices.get(row);
      setIfChanged(row, 'aria-rowindex', position === undefined ? null : String(position));
    });
  }

  private revalidate():void {
    const draft = this.table.lastRenderPass?.draft;
    this.commit(draft ? this.capture(draft) : null);
  }

  private captureHierarchy(source:WorkPackageCollectionResource, draft:RenderDraft):CapturedRowPositions|null {
    const { rowCount, rowPositions } = source;
    if (rowCount === undefined || !rowPositions) return null;

    const occurrences = draft.occurrences.filter((occurrence) => occurrence.key !== placeholderOccurrenceKey());
    if (occurrences.some((occurrence) => occurrence.workPackageId === null || occurrence.workPackage === null)) return null;

    const body = hierarchyRowPositions(rowCount, rowPositions, occurrences.map((occurrence) => ({
      key: occurrence.key,
      workPackageId: occurrence.workPackageId!,
      ancestorIds: occurrence.key === wpOccurrenceKey(occurrence.workPackageId!) ? this.renderedAncestorIds(occurrence.workPackage!) : null,
    })));
    return body ? { source, body } : null;
  }

  /** Rows re-render from the work package cache, so the cached resource describes the row on screen, not the draft's. */
  private renderedAncestorIds(drafted:WorkPackageResource):string[] {
    return this.states.workPackages.get(drafted.id!).getValueOr(drafted).getAncestors().map((ancestor) => ancestor.id!);
  }

  private withdrawnByMode():boolean {
    return (this.columns.hasRelationColumns() || this.columns.hasChildRelationsColumn())
      && Object.keys(this.relationColumns.current).length > 0;
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

    const occurrences = new Map(this.table.ledger.occurrences
      .filter((occurrence) => occurrence.element !== null)
      .map((occurrence) => [occurrence.element!, occurrence]));
    const indices = new Map<HTMLTableRowElement, number>([[header[0], 1]]);
    const trailers:HTMLTableRowElement[] = [];
    const seen = new Set<ProjectedRowKind>();
    let emptySurrogate:HTMLTableRowElement|null = null;
    for (const row of rows) {
      if (row === header[0]) continue;
      const kind = this.classify(row, occurrences);
      if (kind === 'skipped') continue;
      if (kind === 'ledger') {
        const ordinal = body.ordinals.get(occurrences.get(row)!.key);
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
    return { count, indices };
  }

  private classify(row:HTMLTableRowElement, occurrences:Map<HTMLTableRowElement, RenderedOccurrence>):ProjectedRowKind {
    const occurrence = occurrences.get(row);
    if (occurrence) return occurrence.key === placeholderOccurrenceKey() ? 'skipped' : 'ledger';
    if (!isExposedRow(row)) return 'skipped';
    if (isEmptyResultsRow(row)) return 'empty';
    if (isTotalsRow(this.table, row)) return row.cells.length === 0 ? 'skipped' : 'totals';
    if (isInlineCreateRow(row)) return row.cells.length === 0 ? 'skipped' : 'create';
    return 'foreign';
  }
}
