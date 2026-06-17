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

import { ChangeDetectionStrategy, Component, ElementRef, ViewChild, inject } from '@angular/core';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { QuerySharingChange } from 'core-app/shared/components/modals/share-modal/query-sharing-form.component';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { States } from 'core-app/core/states/states.service';
import { WorkPackagesQueryViewService } from 'core-app/features/work-packages/components/wp-list/wp-query-view.service';

@Component({
  templateUrl: './view-settings.modal.html',
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Default,
})
export class ViewSettingsModalComponent extends OpModalComponent {
  readonly I18n = inject(I18nService);
  readonly states = inject(States);
  readonly querySpace = inject(IsolatedQuerySpace);
  readonly wpListService = inject(WorkPackagesListService);
  readonly wpView = inject(WorkPackagesQueryViewService);
  readonly halNotification = inject(HalResourceNotificationService);
  readonly toastService = inject(ToastService);

  public queryName = '';

  public isStarred = false;

  public isPublic = false;

  public isBusy = false;

  @ViewChild('queryNameField', { static: true }) queryNameField:ElementRef<HTMLInputElement>;

  public text = {
    title: this.I18n.t('js.modals.form_submit.title'),
    text: this.I18n.t('js.modals.form_submit.text'),
    save_as: this.I18n.t('js.label_save_as'),
    label_name: this.I18n.t('js.modals.label_name'),
    label_visibility_settings: this.I18n.t('js.label_visibility_settings'),
    button_save: this.I18n.t('js.modals.button_save'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title'),
  };

  public setValues(change:QuerySharingChange):void {
    this.isStarred = change.isStarred;
    this.isPublic = change.isPublic;
  }

  public onOpen():void {
    this.queryNameField.nativeElement.focus();
  }

  public get afterFocusOn():HTMLElement {
    return document.getElementById('work-packages-settings-button')!;
  }

  public async saveQueryAs($event:Event):Promise<void> {
    $event.preventDefault();

    if (this.isBusy || !this.queryName) {
      return;
    }

    this.isBusy = true;
    this.cdRef.markForCheck();
    const query = this.querySpace.query.value!;
    query.public = this.isPublic;

    try {
      const savedQuery:QueryResource = await this.wpListService.create(query, this.queryName);

      if (this.isStarred && !savedQuery.starred) {
        await this.wpListService.toggleStarred(savedQuery);
      }

      this.closeMe($event);
    } catch (error:unknown) {
      this.halNotification.handleRawError(error);
    } finally {
      this.isBusy = false;
      this.cdRef.markForCheck();
    }
  }
}
