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

import { DestroyRef, Injectable, inject, signal } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { WorkPackageViewDisplayRepresentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { firstValueFrom, Subscription } from 'rxjs';

export const REQUEST_TIMEOUT_MS = 30_000;
export const RENDER_TIMEOUT_MS = 10_000;

/**
 * `outOfDate`: the server may hold a parent change that the table does not show,
 * so the rendered order cannot be used to work out a new parent.
 */
type HierarchyState = 'idle'|'running'|'outOfDate';

interface Deadline {
  exceeded:Promise<void>;
  cancel:() => void;
}

@Injectable()
export class WorkPackageViewHierarchyIdentationService {
  private wpViewHierarchies = inject(WorkPackageViewHierarchiesService);
  private wpDisplayRepresentation = inject(WorkPackageViewDisplayRepresentationService);
  private wpRelationHierarchy = inject(WorkPackageRelationsHierarchyService);
  private apiV3Service = inject(ApiV3Service);
  private querySpace = inject(IsolatedQuerySpace);
  private notificationService = inject(WorkPackageNotificationService);
  private toastService = inject(ToastService);
  private I18n = inject(I18nService);

  private readonly state = signal<HierarchyState>('idle');

  private destroyed = false;

  private readonly cleanups = new Set<() => void>();

  private readonly gone:Promise<void>;

  constructor() {
    this.gone = new Promise((resolve) => {
      inject(DestroyRef).onDestroy(() => {
        this.destroyed = true;
        this.cleanups.forEach((cleanup) => cleanup());
        this.cleanups.clear();
        resolve();
      });
    });
  }

  /**
   * Return whether the current hierarchy mode is active
   */
  public get applicable():boolean {
    return this.wpViewHierarchies.isEnabled && this.wpDisplayRepresentation.isList;
  }

  /**
   * Returns whether the given work package can be indented in the current render order
   * @param workPackage
   */
  public canIndent(workPackage:WorkPackageResource):boolean {
    if (!this.canChange(workPackage)) {
      return false;
    }

    const rendered = this.renderedWorkPackageIds;
    const index = rendered.indexOf(workPackage.id!);

    // We can never indent the first item
    if (index === 0) {
      return false;
    }

    // We can not indent work packages whose predecessors are already their ancestors
    const ancestors = workPackage.ancestorIds;
    const ancestorCount = ancestors.length;

    // We can always indent if the ancestor count is 0
    if (ancestorCount === 0) {
      return true;
    }

    // Otherwise, we can only indent if the predecessor is NOT the last ancestor
    const lastAncestor:string = ancestors[ancestorCount - 1];
    const predecessorId:string = rendered[index - 1];

    return predecessorId !== lastAncestor;
  }

  /**
   * Returns whether the given work package can be outdented
   * @param workPackage
   */
  public canOutdent(workPackage:WorkPackageResource):boolean {
    if (!this.canChange(workPackage)) {
      return false;
    }

    // We can always outdent if the work package has a parent
    return !!workPackage.parent;
  }

  /**
   * Try to indent the work package.
   * @return a Promise settling once the table shows the result, or is known to be out of date
   */
  public indent(workPackage:WorkPackageResource):Promise<void> {
    if (!this.canIndent(workPackage)) {
      return Promise.reject();
    }

    const rendered = this.renderedWorkPackageIds;
    const index = rendered.indexOf(workPackage.id!);
    const predecessorId:string = rendered[index - 1];

    return this.run(workPackage, async () => {
      // If the predecessor is in an ancestor chain,
      // get the first element of the ancestor chain that workPackage is not in.
      // Otherwise, insert under the predecessor.
      const predecessor = await firstValueFrom(this.apiV3Service.work_packages.id(predecessorId).get());
      const difference = predecessor.ancestorIds.filter((id) => !workPackage.ancestorIds.includes(id));

      return difference.length > 0 ? difference[0] : predecessorId;
    });
  }

  /**
   * Try to outdent the work package.
   * @return a Promise settling once the table shows the result, or is known to be out of date
   */
  public outdent(workPackage:WorkPackageResource):Promise<void> {
    if (!this.canOutdent(workPackage)) {
      return Promise.reject();
    }

    // If we have more than one ancestor, just drop the last one
    const { ancestorIds } = workPackage;
    const ancestorCount = ancestorIds.length;
    const newParentId = ancestorCount > 1 ? ancestorIds[ancestorCount - 2] : null;

    return this.run(workPackage, () => Promise.resolve(newParentId));
  }

  private canChange(workPackage:WorkPackageResource):boolean {
    return this.state() === 'idle' && !!workPackage.changeParent && this.applicable;
  }

  private run(workPackage:WorkPackageResource, resolveParent:() => Promise<string|null>):Promise<void> {
    this.state.set('running');

    const operation = Promise.resolve()
      .then(() => Promise.race([this.perform(workPackage, resolveParent), this.gone]))
      .finally(() => {
        if (this.state() === 'running') this.state.set('idle');
        this.querySpace.tableOperation.clear('Hierarchy change finished');
      });

    this.querySpace.tableOperation.putValue(operation);

    // Derived, so that it settles a turn after the published promise: the table is released before a caller acts.
    return operation.then(() => undefined);
  }

  private async perform(workPackage:WorkPackageResource, resolveParent:() => Promise<string|null>):Promise<void> {
    let sent = false;
    let abandoned = false;
    const stopped = () => abandoned || this.destroyed;

    const saving = (async ():Promise<'saved'|'stopped'> => {
      const parentId = await resolveParent();
      if (stopped()) return 'stopped';

      sent = true;
      await this.wpRelationHierarchy.changeParent(workPackage, parentId, { notify: false, origin: this.querySpace });
      return stopped() ? 'stopped' : 'saved';
    })();

    const requests = this.deadline(REQUEST_TIMEOUT_MS);
    let outcome:'saved'|'stopped'|'timedOut';
    try {
      outcome = await Promise.race([saving, requests.exceeded.then(() => 'timedOut' as const)]);
    } catch (error) {
      if (this.destroyed) return;
      // A rejected change does not prove that the server kept the old parent, so the table
      // is kept until a reload shows what the server holds.
      if (sent) await this.showServerState(); else this.notificationService.handleRawError(error, workPackage);
      throw error;
    } finally {
      requests.cancel();
    }

    if (outcome === 'stopped') return;

    if (outcome === 'timedOut') {
      abandoned = true;
      if (sent) {
        this.warnAboutRefresh();
        this.state.set('outOfDate');
        void saving.then(() => this.reconcile(), () => this.reconcile());
      } else {
        this.toastService.addError(this.I18n.t('js.relation_buttons.hierarchy_change_timed_out'));
      }

      throw new Error('Changing the hierarchy timed out');
    }

    if (await this.showServerState()) this.notificationService.showSave(workPackage);
  }

  /**
   * Reloads the table and waits for it to render. When that does not happen in time,
   * warns and keeps hierarchy changes off until it does.
   *
   * @returns whether the table shows the reloaded results
   */
  private async showServerState():Promise<boolean> {
    this.state.set('outOfDate');

    const rendering = this.reloadTable();
    const render = this.deadline(RENDER_TIMEOUT_MS);
    const shown = await Promise
      .race([rendering.then(() => true), render.exceeded.then(() => false)])
      .catch(() => false);
    render.cancel();
    if (this.destroyed) return false;

    if (shown) {
      this.state.set('running');
    } else {
      this.warnAboutRefresh();
      this.recoverWith(rendering);
    }

    return shown;
  }

  private reloadTable():Promise<void> {
    const reload = this.querySpace.reloadTable.value;

    return reload ? reload() : Promise.reject(new Error('No table to reload'));
  }

  private reconcile():void {
    if (!this.destroyed) this.recoverWith(this.reloadTable());
  }

  /**
   * Keeps hierarchy changes off until the given reload has been rendered. Should that
   * fail, reloads again whenever the table renders results from elsewhere.
   */
  private recoverWith(rendering:Promise<void>):void {
    this.state.set('outOfDate');

    const recovered = () => {
      if (this.state() === 'outOfDate') this.state.set('idle');
    };

    void rendering.then(recovered, () => this.onNextRender(() => this.reconcile()));
  }

  /**
   * Calls back once the table has been cleared and rendered again, which only happens
   * when reloaded results are applied. A repaint of the current rows does not count.
   */
  private onNextRender(callback:() => void):void {
    if (this.destroyed) return;

    let cleared = false;
    const subscription = new Subscription();
    const stop = () => {
      subscription.unsubscribe();
      this.cleanups.delete(stop);
    };
    subscription.add(this.querySpace.tableRendered.changes$().subscribe((rows) => {
      if (rows === undefined) {
        cleared = true;
        return;
      }
      if (!cleared) return;

      stop();
      callback();
    }));
    this.cleanups.add(stop);
  }

  private deadline(milliseconds:number):Deadline {
    if (this.destroyed) return { exceeded: new Promise(() => undefined), cancel: () => undefined };

    let cancel = () => undefined as void;
    const exceeded = new Promise<void>((resolve) => {
      const timer = setTimeout(resolve, milliseconds);
      cancel = () => {
        clearTimeout(timer);
        this.cleanups.delete(cancel);
      };
    });
    this.cleanups.add(cancel);

    return { exceeded, cancel: () => cancel() };
  }

  private warnAboutRefresh():void {
    this.toastService.addWarning(this.I18n.t('js.relation_buttons.hierarchy_refresh_failed'));
  }

  /**
   * Get the currently rendered work packages
   */
  private get renderedWorkPackageIds():string[] {
    return this.querySpace.renderedWorkPackageIds.getValueOr([]);
  }
}
