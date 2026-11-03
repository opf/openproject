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

import { DestroyRef, Injector, signal, type Signal } from '@angular/core';
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
import type { RowPositionEvidence } from './semantics/table-row-positions';
import { RowStatePainter, type RowReplacement } from './semantics/row-state-painter';
import { RowClassifier } from './semantics/row-classifier';
import { type MutationExit, type PaintScope, RowMutations } from './row-mutations';

export interface CommittedRows extends Pick<MutationExit, 'scope'> {
  readonly generation:number;
}

interface PendingRender {
  readonly pass:PrimaryRenderPass;
  readonly timeline:boolean;
  readonly positions:RowPositionEvidence;
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

  public readonly rows = new RowClassifier(this);

  public readonly painter = new RowStatePainter(this);

  private readonly mutations = new RowMutations({
    enter: (accumulate) => this.keyboardNavigation?.captureOwnership(accumulate),
    exit: (exit) => this.settle(exit),
  }, () => this.hasPendingRender);

  private readonly committedRowsState = signal<CommittedRows>({ generation: 0, scope: 'all' });

  /** Bumped at the end of every outermost mutation; consumers re-read current state, nothing that produces rows reacts to it. */
  public readonly committedRows:Signal<CommittedRows> = this.committedRowsState.asReadonly();

  private readonly requestedRelationTargets = new Set<string>();

  private pendingRender:PendingRender|null = null;

  private schedulingRender = false;

  /** Resources refreshed for rows this table shows since the query's rows were set up; every commit reapplies them to its rows, which keep the query's structure, and forgets those it no longer shows. */
  private readonly refreshed = new Map<string, WorkPackageResource>();

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

  /** True while `pass` is the committed render or the one waiting for its frame; a superseded or cancelled pass is not current. */
  public isCurrentPass(pass:PrimaryRenderPass):boolean {
    return this.pendingRender?.pass === pass || (this.pendingRender === null && this.lastRenderPass === pass);
  }

  /** True from the ownership capture that starts a full render until its frame commit. */
  public get hasPendingRender():boolean {
    return this.schedulingRender || this.pendingRender !== null;
  }

  public destroy():void {
    if (this.destroyed) return;
    this.pendingRender = null;
    this.refreshed.clear();
    try {
      this.lifetimeInjector.destroy();
    } finally {
      runCleanup(() => this.editing.reset());
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
    this.refreshed.clear();
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

  /**
   * The one way to change rows: captures focus ownership, runs `change`, paints `scope`,
   * notifies keyboard navigation and bumps `committedRows`. Nested calls widen the outermost
   * mutation's scope and settle once at its exit.
   */
  public mutate(scope:PaintScope, change:() => void):void {
    if (this.destroyed) return;
    this.mutations.run(scope, change);
  }

  /** Mutates every rendered occurrence of the work packages; with none rendered, `change` runs with nothing to repaint. */
  public mutateWorkPackages(ids:Iterable<string>, change:() => void):void {
    if (this.destroyed) return;
    const keys = this.ledger.keysOfAll(ids);
    if (keys.size === 0) {
      change();
      return;
    }
    this.mutate(keys, change);
  }

  private settle({ scope, rendered }:MutationExit):void {
    if (this.destroyed) return;
    this.painter.paint(scope);
    this.keyboardNavigation?.rowsChanged({ scope, rendered });
    this.committedRowsState.update(({ generation }) => ({ generation: generation + 1, scope }));
  }

  public setHidden(updates:ReadonlyMap<OccurrenceKey, boolean>):void {
    if (this.destroyed) return;
    this.rebuildPendingRender();
    if (updates.size === 0) return;
    this.mutate('all', () => this.ledger.setHidden(updates));
    this.publishRendered();
  }

  private rebuildPendingRender():void {
    if (this.pendingRender) {
      this.performRenderPass({ timeline: this.pendingRender.timeline });
    }
  }

  /**
   * Redraw single rows for a given work package being updated.
   */
  public refreshRows(workPackage:WorkPackageResource) {
    if (this.destroyed) return;
    const id = workPackage.id!;
    if (this.hasPendingRender || this.ledger.keysOf(id).size > 0) this.refreshed.set(id, workPackage);
    // While the next query loads its rows, the committed ones are on their way out
    if (this.querySpace.tableRendered.hasValue()) this.refreshCommitted([[id, workPackage]]);
  }

  private reapplyRefreshed():void {
    this.refreshed.forEach((_, id) => {
      if (this.ledger.keysOf(id).size === 0) this.refreshed.delete(id);
    });
    this.refreshCommitted(this.refreshed.entries());
  }

  private refreshCommitted(updates:Iterable<[string, WorkPackageResource]>):void {
    const pass = this.lastRenderPass;
    if (!pass) return;
    const shown = Array.from(updates).filter(([id]) => this.ledger.keysOf(id).size > 0);
    if (shown.length === 0) return;

    this.mutate(this.ledger.keysOfAll(shown.map(([id]) => id)), () => {
      const replacements:RowReplacement[] = [];
      shown.forEach(([id, workPackage]) => {
        this.ledger.byWorkPackageId(id).forEach((occurrence) => {
          const previous = occurrence.element;
          const replacement = pass.refresh(occurrence, workPackage);
          if (replacement) {
            this.ledger.replaceElement(occurrence.key, replacement);
            replacements.push({ key: occurrence.key, previous, replacement });
          }
        });
      });
      this.painter.carryPositions(replacements);
    });
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
    this.keyboardNavigation?.captureOwnership(this.mutations.depth > 0 || this.hasPendingRender);
    this.schedulingRender = true;
    try {
      this.editing.reset();
      const promoted = timeline || this.pendingRender?.timeline === true;
      const pass = this.rowBuilder.buildRows({ timeline: promoted });
      const pending:PendingRender = { pass, timeline: promoted, positions: this.painter.capturePositions(pass.draft) };
      this.pendingRender = pending;
      this.uiWork.frame(() => this.commitRender(pending));
    } finally {
      this.schedulingRender = false;
    }
  }

  private commitRender(pending:PendingRender):void {
    if (this.destroyed || this.pendingRender !== pending) return;
    try {
      this.mutations.run('all', () => {
        this.pendingRender = null;
        const { pass } = pending;
        this.tbody.replaceChildren(pass.tableBody);
        const timelinePass = pending.timeline ? pass.timeline : null;
        if (timelinePass) {
          this.timelineBody.replaceChildren(timelinePass.timelineBody);
        }
        this.ledger.commit(pass.draft);
        this.painter.commitPositions(pending.positions);
        this.lastRenderPass = pass;
        this.reapplyRefreshed();
      }, { rendered: true });
    } finally {
      if (this.lastRenderPass === pending.pass) this.publishRendered();
    }
  }

  private publishRendered():void {
    this.querySpace.tableRendered.putValue(this.ledger.snapshot());
  }

  setGroupsCollapseState(newState:Record<string, boolean>) {
    if (this.destroyed) return;
    const t0 = performance.now();
    this.mutate('all', () => {
      this.querySpace.collapsedGroups.putValue(newState);
      const updates = this.groupedRowsBuilder.refreshExpansionState();
      this.rebuildPendingRender();
      if (updates.size > 0) this.ledger.setHidden(updates);
    });
    if (this.ledger.generation > 0) this.publishRendered();
    const t1 = performance.now();

    debugLog(`Group redraw took ${t1 - t0} milliseconds.`);
  }
}
