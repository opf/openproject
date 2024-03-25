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
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  Injector,
  OnInit,
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

@Component({
  templateUrl: './progress-popover-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProgressPopoverEditFieldComponent extends ProgressEditFieldComponent implements OnInit {
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
  ) {
    super(I18n, elementRef, change, schema, handler, cdRef, injector);
  }

  ngOnInit() {
    super.ngOnInit();
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    this.frameSrc = this.pathHelper.workPackageProgressModalPath(this.resource.id as string);
    this.frameId = 'work_package_progress_modal';
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
