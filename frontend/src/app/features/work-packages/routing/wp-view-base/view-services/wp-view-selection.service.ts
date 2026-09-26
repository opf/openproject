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

import { DestroyRef, Injectable, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { States } from 'core-app/core/states/states.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageViewBaseService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-base.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import Mousetrap from 'mousetrap';

import { BatchSelection, SelectionItem } from 'core-common/batch-selection';
import {
  anchoredOccurrence,
  occurrenceRangeIds,
  sameOccurrence,
  selectableOccurrences,
  selectAllAnchor,
} from './rendered-occurrences';

export interface WorkPackageViewSelectionState {
  selected:Record<string, boolean>;
}

@Injectable()
export class WorkPackageViewSelectionService extends WorkPackageViewBaseService<WorkPackageViewSelectionState> {
  readonly states = inject(States);
  readonly opContextMenu = inject(OPContextMenuService);

  private readonly model = new BatchSelection();
  private readonly destroyRef = inject(DestroyRef);

  private item(id:string):SelectionItem {
    return { type: 'work_package', id };
  }

  private snapshot():WorkPackageViewSelectionState {
    return { selected: Object.fromEntries(this.model.items().map(({ id }) => [id, true])) };
  }

  private publish():void {
    super.update(this.snapshot());
  }

  private importIds(ids:string[]):void {
    this.model.replaceItems(ids.map((id) => this.item(id)));
  }

  private reconcileAnchor(rows:RenderedWorkPackage[]):void {
    if (this.model.anchor && !anchoredOccurrence(rows, this.model.anchor)) {
      this.model.clearAnchor();
    }
  }

  public constructor() {
    super();
    this.reset();
    this.querySpace.tableRendered.values$()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((rows) => this.reconcileAnchor(rows));
    this.destroyRef.onDestroy(() => {
      this.model.clear();
      Mousetrap.unbind(['command+d', 'ctrl+d']);
    });
  }

  public isSelected(id:string):boolean { return this.model.has(this.item(id)); }
  public get selectionCount():number { return this.model.size; }
  public get isEmpty():boolean { return this.model.size === 0; }
  public getSelectedWorkPackageIds():string[] { return Object.keys(this.snapshot().selected); }

  public reset():void {
    this.model.clear();
    this.publish();
  }

  public override clear(reason:string):void {
    this.model.clear();
    super.clear(reason);
  }

  public override update(state:WorkPackageViewSelectionState):void {
    this.importIds(Object.keys(state.selected).filter((id) => state.selected[id]));
    this.publish();
  }

  public initializeSelection(ids:string[]):void {
    this.importIds(ids);
    this.updatesState.clear();
    this.pristineState.putValue(this.snapshot());
  }

  public override initialize(_query:QueryResource, _results:WorkPackageCollectionResource):void {
    this.pristineState.putValue(this.snapshot());
  }

  /**
   * Selects `id` alone if nothing is selected; a non-empty selection, its
   * anchor and its range session are left as the user made them.
   *
   * @remarks
   * Reached only through
   * {@link WorkPackageViewFocusService.initializeSelectionAndFocus}.
   */
  public ensureSelected(id:string):void {
    if (!this.isEmpty) return;
    this.replaceSelection(id);
  }

  /** Selects `id` alone with no rendered occurrence and therefore no anchor. */
  public replaceSelection(id:string):void {
    this.importIds([id]);
    this.publish();
  }

  public replaceOccurrence(row:RenderedWorkPackage):void {
    if (!row.workPackageId) return;
    this.model.replace(this.item(row.workPackageId), 'view', row.classIdentifier);
    this.publish();
  }

  public toggleOccurrence(row:RenderedWorkPackage):void {
    if (!row.workPackageId) return;
    this.model.toggle(this.item(row.workPackageId), 'view', row.classIdentifier);
    this.publish();
  }

  public rangeTo(row:RenderedWorkPackage, rows:RenderedWorkPackage[]):void {
    if (!row.workPackageId || !rows.some((candidate) => sameOccurrence(candidate, row))) return;
    this.reconcileAnchor(rows);
    const ids = occurrenceRangeIds(rows, this.model.anchor, row);
    if (ids === null) {
      this.replaceOccurrence(row);
      return;
    }
    this.model.range(ids.map((id) => this.item(id)));
    this.publish();
  }

  public selectAll(rows:RenderedWorkPackage[], requestedAnchor?:RenderedWorkPackage):void {
    const selectable = selectableOccurrences(rows);
    const anchor = selectAllAnchor(selectable, requestedAnchor);
    if (!anchor) return;
    this.model.selectAll(selectable.map((candidate) => this.item(candidate.workPackageId!)), {
      ...this.item(anchor.workPackageId!), listKey: 'view', occurrenceKey: anchor.classIdentifier,
    });
    this.publish();
    this.opContextMenu.close();
  }

  public getSelectedWorkPackages():WorkPackageResource[] {
    return this.getSelectedWorkPackageIds().map((id) => this.states.workPackages.get(id).value!);
  }

  public registerDeselectAllListener() {
    // Bind CTRL+D to deselect all work packages
    Mousetrap.bind(['command+d', 'ctrl+d'], (e) => {
      this.reset();
      e.preventDefault();

      this.opContextMenu.close();
      return false;
    });
  }

  valueFromQuery(_query:QueryResource, _results:WorkPackageCollectionResource):WorkPackageViewSelectionState|undefined {
    return undefined;
  }
}
