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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { filter, map, switchMap } from 'rxjs/operators';
import { Observable, timer } from 'rxjs';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { TimeEntryTimerService } from 'core-app/shared/components/time_entries/services/time-entry-timer.service';
import { formatElapsedTime } from 'core-app/features/work-packages/components/wp-timer-button/time-formatter.helper';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

@Component({
  selector: 'op-wp-timer-button',
  templateUrl: './wp-timer-button.component.html',
  styleUrls: ['./wp-timer-button.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageTimerButtonComponent extends UntilDestroyedMixin {
  readonly injector = inject(Injector);
  readonly I18n = inject(I18nService);
  readonly apiV3Service = inject(ApiV3Service);
  readonly timeEntryService = inject(TimeEntryTimerService);
  readonly halEditing = inject(HalResourceEditingService);
  readonly schemaCache = inject(SchemaCacheService);
  readonly timezoneService = inject(TimezoneService);
  readonly toastService = inject(ToastService);
  readonly cdRef = inject(ChangeDetectorRef);

  @Input() public workPackage:WorkPackageResource;
  readonly PathHelper = inject(PathHelperService);
  readonly TurboRequests = inject(TurboRequestsService);

  timer$ = this.timeEntryService.activeTimer$;

  elapsed$:Observable<string> = timer(0, 1000)
    .pipe(
      switchMap(() => this.timer$),
      filter((timeEntry) => timeEntry !== null),
      map((timeEntry:TimeEntryResource) => formatElapsedTime(timeEntry.createdAt as string)),
    );

  text = {
    workPackage: this.I18n.t('js.label_work_package'),
    start_timer: this.I18n.t('js.timer.start_new_timer'),
    stop_timer: this.I18n.t('js.timer.button_stop'),
    timer_already_stopped: this.I18n.t('js.timer.timer_already_stopped'),
  };


  activeForWorkPackage(entry:TimeEntryResource | null):boolean {
    return !!entry && entry.entity.href === this.workPackage.href;
  }

  clear():void {
    this.timeEntryService.timer$.next(null);
  }

  start():void {
    this.timeEntryService.start(this.workPackage);
  }

  stop():void {
   void this.timeEntryService.stop();
  }
}
