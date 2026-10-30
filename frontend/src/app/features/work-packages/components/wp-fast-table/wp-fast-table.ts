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

import { DestroyRef, Injector } from '@angular/core';
import { Subject } from 'rxjs';
import { generateId } from 'core-app/shared/helpers/dom-helpers';
import { runCleanup } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { TableUiWork } from './table-ui-work';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { States } from 'core-app/core/states/states.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { WorkPackageTableConfiguration } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { WorkPackageTimelineTableController } from '../wp-table/timeline/container/wp-timeline-container.directive';
import { GroupedRowsBuilder } from './builders/modes/grouped/grouped-rows-builder';
import { HierarchyRowsBuilder } from './builders/modes/hierarchy/hierarchy-rows-builder';
import { PlainRowsBuilder } from './builders/modes/plain/plain-rows-builder';
import { RowsBuilder } from './builders/modes/rows-builder';
import type { PrimaryRenderPass, RenderPassOptions } from './builders/primary-render-pass';
import { type OccurrenceKey, RenderedOccurrenceLedger } from './rendered-occurrence-ledger';
import { WorkPackageTableEditingContext } from './wp-table-editing';
import type { WorkPackageTableRow } from './wp-table.interfaces';
import type { KeyboardNavigation } from './handlers/state/keyboard/keyboard-navigation-transformer';
import type { TableSelectionFeedback } from './handlers/state/selection-feedback';
import { TableRowPositions, type CapturedRowPositions } from './semantics/table-row-positions';
import { paintSectionExposure, TreegridSemantics } from './semantics/treegrid-semantics';

interface PendingRender {
  readonly pass:PrimaryRenderPass;
  readonly timeline:boolean;
  readonly positions:CapturedRowPositions|null;
}

export class WorkPackageTable {
  @LazyInject() querySpace:IsolatedQuerySpace;

  @LazyInject() apiV3Service:ApiV3Service;

  @LazyInject() states:States;

  @LazyInject() I18n!:I18nService;

  @LazyInject() workPackageViewCollapsedGroupsService:WorkPackageViewCollapsedGroupsService;

  public readonly domId = generateId('wp-table');

  public originalRows:string[] = [];

  public colspan:number;

  public originalRowIndex:Record<string, WorkPackageTableRow> = {};

  private readonly lifetimeInjector = Injector.create({ providers: [], parent: this.injector });

  public readonly destroyRef = this.lifetimeInjector.get(DestroyRef);

  public readonly uiWork = new TableUiWork(this.destroyRef);

  private hierarchyRowsBuilder = new HierarchyRowsBuilder(this.injector, this);

  private groupedRowsBuilder = new GroupedRowsBuilder(this.injector, this);

  private plainRowsBuilder = new PlainRowsBuilder(this.injector, this);

  // WP rows builder
  // Ordered by priority
  private builders = [this.hierarchyRowsBuilder, this.groupedRowsBuilder, this.plainRowsBuilder];

  // Last render pass used for refreshing single rows
  public lastRenderPass:PrimaryRenderPass|null = null;

  public readonly ledger = new RenderedOccurrenceLedger();

  public keyboardNavigation:KeyboardNavigation|null = null;

  public selectionFeedback:TableSelectionFeedback|null = null;

  public readonly semantics:TreegridSemantics|null = this.configuration.keyboardNavigationEnabled ? new TreegridSemantics(this) : null;

  public readonly rowPositions:TableRowPositions|null = this.configuration.keyboardNavigationEnabled ? new TableRowPositions(this) : null;

  private readonly rowsRefreshedSubject = new Subject<string>();

  /** Emits a work package id after `refreshRows` replaced at least one of its rendered rows, or an edge row key after that row re-rendered. */
  public readonly rowsRefreshed$ = this.rowsRefreshedSubject.asObservable();

  private readonly requestedRelationTargets = new Set<string>();

  private pendingRender:PendingRender|null = null;

  // Work package editing context handler in the table, which handles open forms
  // and their contexts
  public editing:WorkPackageTableEditingContext = new WorkPackageTableEditingContext(this, this.injector);

  constructor(
    public readonly injector:Injector,
    public tableAndTimelineContainer:HTMLElement,
    public scrollContainer:HTMLElement,
    public tbody:HTMLTableSectionElement,
    public timelineBody:HTMLElement,
    public timelineController:WorkPackageTimelineTableController,
    public configuration:WorkPackageTableConfiguration,
  ) {
  }

  public get destroyed():boolean {
    return this.destroyRef.destroyed;
  }

  /** True between scheduling a full render and its frame commit. */
  public get hasPendingRender():boolean {
    return this.pendingRender !== null;
  }

  public destroy():void {
    if (this.destroyed) return;
    try {
      this.lifetimeInjector.destroy();
    } finally {
      runCleanup(() => this.editing.reset());
      this.rowsRefreshedSubject.complete();
    }
  }

  public get renderedRows():RenderedWorkPackage[] {
    return this.querySpace.tableRendered.getValueOr([]);
  }

  public get rowBuilder():RowsBuilder {
    return this.builders.find((builder:RowsBuilder) => builder.isApplicable(this))!;
  }

  /**
   * Build the row index and positions from the given set of ordered work packages.
   * @param rows
   */
  private buildIndex(rows:WorkPackageResource[]) {
    this.originalRowIndex = {};
    this.originalRows = rows.map((wp:WorkPackageResource, i:number) => {
      const wpId = wp.id!;

      // Ensure we get the latest version
      wp = this.apiV3Service.work_packages.cache.current(wpId, wp)!;

      this.originalRowIndex[wpId] = { object: wp, workPackageId: wpId, position: i };
      return wpId;
    });
  }

  /**
   *
   * @param rows
   */
  public initialSetup(rows:WorkPackageResource[]) {
    if (this.destroyed) return;
    // Build the row representation
    this.buildIndex(rows);
    this.requestedRelationTargets.clear();

    // Draw work packages
    this.redrawTableAndTimeline();
  }

  public requestRelationTargets(ids:string[]):string[] {
    const claimed = Array.from(new Set(ids)).filter((id) => !this.requestedRelationTargets.has(id));
    claimed.forEach((id) => this.requestedRelationTargets.add(id));
    return claimed;
  }

  public releaseRelationTargets(ids:string[]):void {
    ids.forEach((id) => this.requestedRelationTargets.delete(id));
  }

  /**
   * Removes the contents of this table's tbody and redraws
   * all elements.
   */
  public redrawTableAndTimeline() {
    if (this.destroyed) return;
    this.performRenderPass({ timeline: true });
  }

  /**
   * Redraw all elements in the table section only
   */
  public redrawTable() {
    if (this.destroyed) return;
    this.performRenderPass({ timeline: false });
  }

  public setHidden(updates:ReadonlyMap<OccurrenceKey, boolean>):void {
    if (this.destroyed) return;
    this.rebuildPendingRenderForSemantics();
    if (updates.size === 0) return;
    this.keyboardNavigation?.captureOwnership();
    this.ledger.setHidden(updates);
    this.publishRendered();
  }

  private rebuildPendingRenderForSemantics():void {
    if (this.semantics && this.pendingRender) {
      this.performRenderPass({ timeline: this.pendingRender.timeline });
    }
  }

  /**
   * Redraw single rows for a given work package being updated.
   */
  public refreshRows(workPackage:WorkPackageResource) {
    if (this.destroyed) return;
    const pass = this.lastRenderPass;
    if (!pass) {
      debugLog('Trying to refresh a singular row without a previous render pass.');
      return;
    }

    this.keyboardNavigation?.captureOwnership();
    let replaced = 0;
    this.ledger.byWorkPackageId(workPackage.id!).forEach((occurrence) => {
      const previous = occurrence.element;
      const replacement = pass.refresh(occurrence, workPackage);
      if (replacement) {
        this.ledger.replaceElement(occurrence.key, replacement);
        if (previous) this.rowPositions?.carry(previous, replacement);
        replaced += 1;
      }
    });

    if (replaced > 0) {
      this.semantics?.paintWorkPackage(workPackage.id!);
      this.rowsRefreshedSubject.next(workPackage.id!);
    }
  }

  public notifyRowsRefreshed(key:string):void {
    this.rowPositions?.paint();
    this.rowsRefreshedSubject.next(key);
  }

  /** Re-exposes a structural section whose rows changed outside the render pass. */
  public reconcileSection(section:HTMLTableSectionElement):void {
    if (!this.semantics) return;
    paintSectionExposure(section);
    this.rowPositions?.paint();
  }

  /**
   * Determine whether we need an empty placeholder row.
   * When D&D is enabled, the table requires a drag target that is non-empty,
   * and the tbody cannot be resized appropriately.
   */
  public get renderPlaceholderRow() {
    return this.configuration.dragAndDropEnabled;
  }

  private performRenderPass({ timeline }:RenderPassOptions):void {
    this.keyboardNavigation?.captureOwnership();
    this.editing.reset();
    const promoted = timeline || this.pendingRender?.timeline === true;
    const pass = this.rowBuilder.buildRows({ timeline: promoted });
    const pending:PendingRender = { pass, timeline: promoted, positions: this.rowPositions?.capture(pass.draft) ?? null };
    this.pendingRender = pending;
    this.uiWork.frame(() => this.commitRender(pending));
  }

  private commitRender(pending:PendingRender):void {
    if (this.destroyed || this.pendingRender !== pending) return;
    this.pendingRender = null;
    const { pass } = pending;
    this.tbody.replaceChildren(pass.tableBody);
    const timelinePass = pending.timeline ? pass.timeline : null;
    if (timelinePass) {
      this.timelineBody.replaceChildren(timelinePass.timelineBody);
    }
    this.ledger.commit(pass.draft);
    this.rowPositions?.commit(pending.positions);
    this.lastRenderPass = pass;
    this.publishRendered();
  }

  private publishRendered():void {
    this.semantics?.paint();
    this.rowPositions?.paint();
    this.querySpace.tableRendered.putValue(this.ledger.snapshot());
  }

  setGroupsCollapseState(newState:Record<string, boolean>) {
    if (this.destroyed) return;
    this.keyboardNavigation?.captureOwnership();
    this.querySpace.collapsedGroups.putValue(newState);

    const t0 = performance.now();
    const updates = this.groupedRowsBuilder.refreshExpansionState();
    this.setHidden(updates);
    if (updates.size === 0) {
      this.publishRendered();
    }
    const t1 = performance.now();

    debugLog(`Group redraw took ${t1 - t0} milliseconds.`);
  }
}
