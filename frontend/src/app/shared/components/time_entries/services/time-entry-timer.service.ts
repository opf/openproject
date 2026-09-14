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

import {
  inject,
  Injectable,
  Injector,
} from '@angular/core';
import {
  filter,
  map,
  tap,
} from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import {
  BehaviorSubject,
  firstValueFrom,
  Observable,
} from 'rxjs';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import moment from 'moment/moment';
import { StopExistingTimerModalComponent } from 'core-app/shared/components/time_entries/timer/stop-existing-timer-modal.component';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { octiconElement } from 'core-app/shared/helpers/op-icon-builder';
import { clockIconData } from '@openproject/octicons-angular';
import { DialogCloseDetail } from 'core-turbo/dialog-stream-action';

@Injectable()
export class TimeEntryTimerService {
  public timer$ = new BehaviorSubject<TimeEntryResource|null|undefined>(undefined);

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
  private halResourceService = inject(HalResourceService);
  private modalService = inject(OpModalService);
  private injector = inject(Injector);

  private closeDialogHandler:EventListener = this.handleTimeEntryDialogClose.bind(this);
  private shouldStartTimerFor:WorkPackageResource|null = null;

  public initialize() {
    // Listen to dialog close events to possibly start a new timer
    document.addEventListener('dialog:close', this.closeDialogHandler);

    // Refresh the timer after some interval to not block other resources
    setTimeout(() => this.refresh().subscribe(), 100);

    this
      .activeTimer$
      .subscribe((entry) => {
        this.removeTimer();

        if (entry) {
          this.renderTimer();
        }
      });
  }

  public refresh():Observable<TimeEntryResource|null> {
    const filters = new ApiV3FilterBuilder();
    filters.add('ongoing', '=', true);

    return this
      .apiV3Service
      .time_entries
      .filtered(filters)
      .get()
      .pipe(
        map((collection) => collection.elements.pop() || null),
        tap((active) => this.timer$.next(active)),
      );
  }

  async stop():Promise<unknown> {
    const active = await firstValueFrom(this.refresh());

    if (!active) {
      return this.toastService.addWarning(this.I18n.t('js.timer.timer_already_stopped'));
    }

    return this.turboRequestsService.request(
      this.pathHelperService.timeEntryEditDialog(active.id!),
      { method: 'GET' },
    );
  }

  start(workPackage:WorkPackageResource):void {
    this
      .refresh()
      .subscribe((active) => {
        if (active) {
          this.showStopModal(active)
            .then(() => {
              this.shouldStartTimerFor = workPackage;
              void this.stop();
            })
            .catch(() => undefined);
        } else {
          this.startTimer(workPackage);
        }
      });
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
      .createTimer(workPackage)
      .subscribe((active) => {
        this.timer$.next(active);
      });
  }

  private createTimer(workPackage:WorkPackageResource):Observable<TimeEntryResource> {
    return this
      .apiV3Service
      .time_entries
      .post(this.timerPayload(workPackage));
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

  private showStopModal(active:TimeEntryResource):Promise<void> {
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
