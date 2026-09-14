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

import { ChangeDetectionStrategy, Component, ElementRef, OnInit, ViewChild, AfterViewInit, OnDestroy, inject } from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { reminderModalUpdated } from 'core-app/features/work-packages/components/wp-reminder-modal/reminder.actions';
import { ReminderPreset } from 'core-app/features/work-packages/components/wp-reminder-modal/reminder.types';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import type { FrameElement, TurboSubmitEndEvent } from '@hotwired/turbo';

@Component({
  templateUrl: './wp-reminder.modal.html',
  styleUrls: ['./wp-reminder.modal.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class WorkPackageReminderModalComponent extends OpModalComponent implements OnInit, AfterViewInit, OnDestroy {
  readonly I18n = inject(I18nService);
  readonly pathHelper = inject(PathHelperService);
  readonly actions$ = inject(ActionsService);
  readonly apiV3Service = inject(ApiV3Service);

  @ViewChild('frameElement') frameElement:ElementRef<FrameElement>;

  // Hide close button so it's not duplicated in primer (WP#51699)
  showCloseButton = false;

  private workPackage:WorkPackageResource;
  public frameSrc:string;
  private preset:ReminderPreset | undefined;

  text = {
    new_title: this.I18n.t('js.work_packages.reminders.title.new'),
    edit_title: this.I18n.t('js.work_packages.reminders.title.edit'),
    subtitle: this.I18n.t('js.work_packages.reminders.subtitle'),
    button_close: this.I18n.t('js.button_close'),
  };

  public title$:Observable<string>;

  private boundListener = this.turboSubmitEndListener.bind(this);

  constructor() {
    super();

    this.workPackage = this.locals.workPackage as WorkPackageResource;
    this.preset = this.locals.preset as ReminderPreset | undefined;
    this.title$ = this
      .isEditMode()
      .pipe(
        map((isEditMode) => (isEditMode ? this.text.edit_title : this.text.new_title)),
      );
  }

  ngOnInit() {
    super.ngOnInit();
    this.updateFrameSrc();
  }

  ngAfterViewInit() {
    // Use event delegation on a parent element that won't be re-rendered
    this.elementRef.nativeElement.addEventListener('turbo:submit-end', this.boundListener);
  }

  ngOnDestroy() {
    super.ngOnDestroy();

    this.elementRef.nativeElement.removeEventListener('turbo:submit-end', this.boundListener);
  }

  onClose():boolean {
    this.actions$.dispatch(reminderModalUpdated({ workPackageId: this.workPackage.id! }));

    return super.onClose();
  }

  private updateFrameSrc():void {
    const url = new URL(
      this.pathHelper.workPackageReminderModalBodyPath(this.workPackage.id!),
      window.location.origin,
    );
    if (this.preset) {
      url.searchParams.set('preset', this.preset);
    }
    this.frameSrc = url.toString();
  }

  private turboSubmitEndListener(event:TurboSubmitEndEvent) {
    const { fetchResponse } = event.detail;

    if (fetchResponse?.succeeded) {
      this.closeMe();
      this.onClose();
    }
  }

  /**
   * Check if there is already a reminder for the work package
   * so we can determine if we are in edit or new mode
   */
  private isEditMode():Observable<boolean> {
    return this
      .apiV3Service
      .work_packages
      .id(this.workPackage.id!)
      .reminders
      .get()
      .pipe(
        map((collection:CollectionResource) => { return collection.total > 0; }),
      );
  }
}
