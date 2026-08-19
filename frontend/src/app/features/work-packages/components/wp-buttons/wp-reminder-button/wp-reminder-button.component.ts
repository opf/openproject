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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, inject } from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { notificationCountChanged } from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';
import { reminderModalUpdated } from 'core-app/features/work-packages/components/wp-reminder-modal/reminder.actions';
import {
  WorkPackageReminderModalComponent,
} from 'core-app/features/work-packages/components/wp-reminder-modal/wp-reminder.modal';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { merge, Observable } from 'rxjs';
import { filter, map, startWith, switchMap } from 'rxjs/operators';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-reminder-button',
  templateUrl: './wp-reminder-button.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageReminderButtonComponent extends UntilDestroyedMixin implements OnInit {
  readonly I18n = inject(I18nService);
  readonly opModalService = inject(OpModalService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly apiV3Service = inject(ApiV3Service);
  readonly actions$ = inject(ActionsService);
  readonly storeService = inject(IanBellService);

  @Input() public workPackage:WorkPackageResource;

  hasReminder$:Observable<boolean>;

  public buttonTitle = this.I18n.t('js.work_packages.reminders.button_label');

  ngOnInit() {
    const reminderModalUpdated$ = this
      .actions$
      .ofType(reminderModalUpdated)
      .pipe(
        map((action) => action.workPackageId),
        filter((id) => id === this.workPackage.id?.toString()),
        startWith(null),
      );
    const notificationCountChanged$ = this
      .actions$
      .ofType(notificationCountChanged)
      .pipe(
        map((action) => action.count),
      );

    this.hasReminder$ = merge(
      notificationCountChanged$,
      reminderModalUpdated$,
    ).pipe(
      switchMap(() => this.countReminders()),
      map((count) => count > 0),
    );
  }

  openModal():void {
    this.opModalService.show(WorkPackageReminderModalComponent, 'global', { workPackage: this.workPackage }, false, true);
  }

  private countReminders():Observable<number> {
    return this
      .apiV3Service
      .work_packages
      .id(this.workPackage.id!)
      .reminders
      .get()
      .pipe(
        map((collection:CollectionResource) => { return collection.total; }),
      );
  }
}
