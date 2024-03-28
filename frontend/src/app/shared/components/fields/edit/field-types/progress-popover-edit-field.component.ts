/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2010-2024 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  Injector,
  OnDestroy,
  OnInit,
  ViewChild,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  ProgressEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/progress-edit-field.component';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import {
  OpEditingPortalChangesetToken,
  OpEditingPortalHandlerToken,
  OpEditingPortalSchemaToken,
} from 'core-app/shared/components/fields/edit/edit-field.component';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

@Component({
  templateUrl: './progress-popover-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProgressPopoverEditFieldComponent extends ProgressEditFieldComponent implements OnInit, AfterViewInit, OnDestroy {
  @ViewChild('frameElement') frameElement:ElementRef<HTMLIFrameElement>;

  text = {
    title: this.I18n.t('js.work_packages.progress.title'),
    button_close: this.I18n.t('js.button_close'),
  };

  public frameSrc:string;
  public frameId:string;

  opened = false;

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    @Inject(OpEditingPortalChangesetToken) protected change:ResourceChangeset<HalResource>,
    @Inject(OpEditingPortalSchemaToken) public schema:IFieldSchema,
    @Inject(OpEditingPortalHandlerToken) readonly handler:EditFieldHandler,
    readonly cdRef:ChangeDetectorRef,
    readonly injector:Injector,
    readonly pathHelper:PathHelperService,
    private halEvents:HalEventsService,
    private toastService:ToastService,
    private apiV3Service:ApiV3Service,
  ) {
    super(I18n, elementRef, change, schema, handler, cdRef, injector);
  }

  ngOnInit() {
    super.ngOnInit();
    /*
      Append clicked field name to URL query props
      in order to indicate which field should be focused on load.
    */
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    this.frameSrc = `${this.pathHelper.workPackageProgressModalPath(this.resource.id as string)}?field=${this.name}`;
    this.frameId = 'work_package_progress_modal';
  }

  ngAfterViewInit() {
    this
      .frameElement
      .nativeElement
      .addEventListener('turbo:submit-end', this.propagateSuccessfulUpdate.bind(this));
  }

  ngOnDestroy() {
    super.ngOnDestroy();

    this
      .frameElement
      .nativeElement
      .removeEventListener('turbo:submit-end', this.propagateSuccessfulUpdate.bind(this));
  }

  private propagateSuccessfulUpdate(event:CustomEvent) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    const { fetchResponse } = event.detail;

    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    if (fetchResponse.succeeded) {
      this.halEvents.push(
        this.resource as WorkPackageResource,
        { eventType: 'updated' },
      );

      void this.apiV3Service.work_packages.id(this.resource as WorkPackageResource).refresh();

      this.onModalClosed();

      this.toastService.addSuccess(this.I18n.t('js.notice_successful_update'));
    }
  }

  public onInputClick(event:MouseEvent) {
    event.stopPropagation();
  }

  public showProgressModal():void {
    this.opened = true;
    this.cdRef.detectChanges();
  }

  public onModalClosed():void {
    this.opened = false;

    if (!this.handler.inEditMode) {
      this.handler.deactivate(false);
    }
  }

  public closeMe():void {
    this.cancel();
  }

  public cancel():void {
    this.handler.reset();
    this.onModalClosed();
  }
}
