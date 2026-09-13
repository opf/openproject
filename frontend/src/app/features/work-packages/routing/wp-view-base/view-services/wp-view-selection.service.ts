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

import { Injectable, OnDestroy, inject } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { States } from 'core-app/core/states/states.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageViewBaseService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-base.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import Mousetrap from 'mousetrap';

import { Subject, takeUntil } from 'rxjs';
import { BatchSelection, SelectionItem } from 'core-common/batch-selection';

export interface WorkPackageViewSelectionState {
  selected:Record<string, boolean>;
}

@Injectable()
export class WorkPackageViewSelectionService extends WorkPackageViewBaseService<WorkPackageViewSelectionState> implements OnDestroy {
  readonly states = inject(States);
  readonly opContextMenu = inject(OPContextMenuService);

  private readonly model = new BatchSelection();
  private anchorOccurrence:RenderedWorkPackage|null = null;
  private readonly destroyed = new Subject<void>();

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
    this.model.selectAll(ids.map((id) => this.item(id)), null);
    this.model.clearAnchor();
    this.anchorOccurrence = null;
  }

  private reconcileAnchor(rows:RenderedWorkPackage[]):void {
    if (this.anchorOccurrence && !rows.some((row) =>
      row.classIdentifier === this.anchorOccurrence!.classIdentifier
      && row.workPackageId === this.anchorOccurrence!.workPackageId)) {
      this.anchorOccurrence = null;
      this.model.clearAnchor();
    }
  }

  public constructor() {
    super();
    this.reset();
    this.querySpace.tableRendered.values$()
      .pipe(takeUntil(this.destroyed))
      .subscribe((rows) => this.reconcileAnchor(rows));
  }

  public isSelected(id:string):boolean { return this.model.has(this.item(id)); }
  public get selectionCount():number { return this.model.size; }
  public get isEmpty():boolean { return this.model.size === 0; }
  public getSelectedWorkPackageIds():string[] { return Object.keys(this.snapshot().selected); }

  public reset():void {
    this.model.clear();
    this.anchorOccurrence = null;
    this.publish();
  }

  public override clear(reason:string):void {
    this.model.clear();
    this.anchorOccurrence = null;
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

  public setRowState(id:string, selected:boolean):void {
    const ids = new Set(this.getSelectedWorkPackageIds());
    if (selected) ids.add(id); else ids.delete(id);
    this.importIds([...ids]);
    this.publish();
  }

  public ensureSelected(id:string):void {
    if (this.isEmpty) this.setRowState(id, true);
  }

  public replaceOccurrence(row:RenderedWorkPackage):void {
    if (!row.workPackageId) return;
    this.model.replace(this.item(row.workPackageId), 'view');
    this.anchorOccurrence = { ...row };
    this.publish();
  }

  public toggleOccurrence(row:RenderedWorkPackage):void {
    if (!row.workPackageId) return;
    this.model.toggle(this.item(row.workPackageId), 'view');
    this.anchorOccurrence = { ...row };
    this.publish();
  }

  public rangeTo(row:RenderedWorkPackage, rows:RenderedWorkPackage[]):void {
    const end = rows.findIndex((candidate) => candidate.classIdentifier === row.classIdentifier
      && candidate.workPackageId === row.workPackageId);
    if (end < 0 || !row.workPackageId) return;
    this.reconcileAnchor(rows);
    if (!this.anchorOccurrence) {
      this.replaceOccurrence(row);
      return;
    }
    const start = rows.findIndex((candidate) => candidate.classIdentifier === this.anchorOccurrence!.classIdentifier
      && candidate.workPackageId === this.anchorOccurrence!.workPackageId);
    const items = rows.slice(Math.min(start, end), Math.max(start, end) + 1)
      .filter((candidate) => candidate.workPackageId !== null)
      .map((candidate) => this.item(candidate.workPackageId!));
    this.model.range(items);
    this.publish();
  }

  public selectAll(rows:RenderedWorkPackage[], requestedAnchor?:RenderedWorkPackage):void {
    const selectable = rows.filter((row) => Boolean(row.workPackageId));
    if (selectable.length === 0) return;
    const anchor = selectable.find((row) => row.classIdentifier === requestedAnchor?.classIdentifier
      && row.workPackageId === requestedAnchor?.workPackageId) ?? selectable[0];
    this.model.selectAll(selectable.map((row) => this.item(row.workPackageId!)), {
      ...this.item(anchor.workPackageId!), listKey: 'view',
    });
    this.anchorOccurrence = { ...anchor };
    this.publish();
  }

  public setSelection(id:string, position:number):void {
    const row = this.querySpace.tableRendered.getValueOr([])[position];
    if (row?.workPackageId === id) {
      this.replaceOccurrence(row);
    } else {
      this.importIds([id]);
      this.publish();
    }
  }

  public toggleRow(id:string):void {
    this.setRowState(id, !this.isSelected(id));
  }

  public setMultiSelectionFrom(rows:RenderedWorkPackage[], id:string, position:number):void {
    const row = rows[position];
    if (row?.workPackageId === id) this.rangeTo(row, rows);
  }

  public getSelectedWorkPackages():WorkPackageResource[] {
    return this.getSelectedWorkPackageIds().map((id) => this.states.workPackages.get(id).value!);
  }

  ngOnDestroy():void {
    this.destroyed.next();
    this.destroyed.complete();
    this.model.clear();
    this.anchorOccurrence = null;
    Mousetrap.unbind(['command+d', 'ctrl+d']);
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
