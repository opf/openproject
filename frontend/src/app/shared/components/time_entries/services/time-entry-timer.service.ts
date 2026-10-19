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

import {
  inject,
  Injectable,
  Injector,
} from '@angular/core';
import { filter, map, tap } from 'rxjs/operators';
import { BehaviorSubject, firstValueFrom } from 'rxjs';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { formatTimeEntryEntityName, TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import moment from 'moment/moment';
import { StopExistingTimerModalComponent } from 'core-app/shared/components/time_entries/timer/stop-existing-timer-modal.component';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { octiconElement } from 'core-app/shared/helpers/op-icon-builder';
import { clockIconData } from '@openproject/octicons-angular';
import { DialogCloseDetail } from 'core-turbo/dialog-stream-action';
import { OngoingTimer } from 'core-app/shared/components/time_entries/services/ongoing-timer';

export const TIMER_CHANGED_EVENT = 'op-dispatched:time-entries:timer-changed';
const TIMER_FRAME_ID = 'my_timers';
const AVATAR_ELEMENT = 'opce-principal';

@Injectable()
export class TimeEntryTimerService {
  public timer$ = new BehaviorSubject<OngoingTimer|null|undefined>(undefined);

  public activeTimer$ = this
    .timer$
    .asObservable()
    .pipe(
      filter((item) => item !== undefined),
    );

  private apiV3Service = inject(ApiV3Service);
  private toastService = inject(ToastService);
  private turboRequestsService = inject(TurboRequestsService);
  private pathHelperService = inject(PathHelperService);
  private I18n = inject(I18nService);
  private modalService = inject(OpModalService);
  private injector = inject(Injector);

  private closeDialogHandler:EventListener = this.handleTimeEntryDialogClose.bind(this);
  private frameLoadHandler:EventListener = this.handleFrameLoad.bind(this);
  private shouldStartTimerFor:WorkPackageResource|null = null;
  private initialized = false;

  public initialize() {
    if (!this.initialized) {
      this.initialized = true;
      document.addEventListener('dialog:close', this.closeDialogHandler);
      document.addEventListener('turbo:frame-load', this.frameLoadHandler);

      this
        .activeTimer$
        .subscribe(() => { void this.syncBadge(); });
    }

    this.timer$.next(this.readState());
  }

  async stop():Promise<unknown> {
    const active = await this.fetchActiveTimer();

    if (!active) {
      return this.toastService.addWarning(this.I18n.t('js.timer.timer_already_stopped'));
    }

    return this.turboRequestsService.request(
      this.pathHelperService.timeEntryEditDialog(active.id),
      { method: 'GET' },
    );
  }

  async start(workPackage:WorkPackageResource):Promise<void> {
    const active = await this.fetchActiveTimer();

    if (!active) {
      this.startTimer(workPackage);
      return;
    }

    try {
      await this.showStopModal(active);
    } catch {
      return;
    }

    this.shouldStartTimerFor = workPackage;
    void this.stop();
  }

  private fetchActiveTimer():Promise<OngoingTimer|null> {
    const filters = new ApiV3FilterBuilder();
    filters.add('ongoing', '=', true);

    return firstValueFrom(
      this
        .apiV3Service
        .time_entries
        .filtered(filters)
        .get()
        .pipe(
          map((collection) => {
            const entry = collection.elements.pop();
            return entry ? TimeEntryTimerService.toOngoingTimer(entry) : null;
          }),
          tap((active) => this.timer$.next(active)),
        ),
    );
  }

  private static toOngoingTimer(entry:TimeEntryResource):OngoingTimer {
    return {
      id: entry.id!,
      createdAt: entry.createdAt as string,
      entityId: idFromLink(entry.entity.href),
      entityName: formatTimeEntryEntityName(entry.entity),
    };
  }

  private readState():OngoingTimer|null {
    const payload = document
      .querySelector<HTMLElement>(`#${TIMER_FRAME_ID} [data-ongoing-timer]`)
      ?.dataset
      .ongoingTimer;

    return payload ? JSON.parse(payload) as OngoingTimer : null;
  }

  // Upgrading the avatar custom element clears its children, so drawing the
  // badge before the element is defined (i.e. during app initialization) loses it.
  private async syncBadge():Promise<void> {
    await customElements.whenDefined(AVATAR_ELEMENT);

    this.removeTimer();
    if (this.timer$.value) {
      this.renderTimer();
    }
  }

  private renderTimer() {
    const timerElement = document.createElement('span');
    const icon = octiconElement(clockIconData, 'xsmall');
    timerElement.classList.add('op-principal--timer');
    timerElement.appendChild(icon);

    const avatar = document.querySelector<HTMLElement>('.op-top-menu-user-avatar');
    avatar?.appendChild(timerElement);
  }

  private removeTimer() {
    const timerElement = document.querySelector<HTMLElement>('.op-principal--timer');
    timerElement?.remove();
  }

  private startTimer(workPackage:WorkPackageResource):void {
    this
      .apiV3Service
      .time_entries
      .post(this.timerPayload(workPackage))
      .subscribe(() => document.dispatchEvent(new CustomEvent(TIMER_CHANGED_EVENT)));
  }

  private timerPayload(workPackage:WorkPackageResource) {
    return {
      spentOn: moment().format('YYYY-MM-DD'),
      hours: null,
      ongoing: true,
      _links: {
        workPackage: {
          href: workPackage.href,
        },
      },
    };
  }

  private showStopModal(active:OngoingTimer):Promise<void> {
    return new Promise<void>((resolve, reject) => {
      this
        .modalService
        .show(StopExistingTimerModalComponent, this.injector, { timer: active })
        .subscribe((modal) => modal.closingEvent.subscribe(() => {
          if (modal.confirmed) {
            resolve();
          } else {
            reject(new Error());
          }
        }));
    });
  }

  private handleFrameLoad(event:Event):void {
    if ((event.target as HTMLElement).id === TIMER_FRAME_ID) {
      this.timer$.next(this.readState());
    }
  }

  private handleTimeEntryDialogClose(event:CustomEvent<DialogCloseDetail>):void {
    const { detail: { dialog, submitted } } = event;
    const isOngoing = dialog.dataset.ongoing === 'true';

    if (dialog.id === 'time-entry-dialog' && submitted && isOngoing) {
      this.timer$.next(null);
      if (this.shouldStartTimerFor) {
        const workPackage = this.shouldStartTimerFor;
        this.shouldStartTimerFor = null;
        this.startTimer(workPackage);
      }
    }
  }
}
