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

import {
  AfterViewInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
  ViewChild,
} from '@angular/core';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TypeResource } from 'core-app/features/hal/resources/type-resource';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { FormResource } from 'core-app/features/hal/resources/form-resource';

@Component({
  templateUrl: './wp-button-macro.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WpButtonMacroModalComponent extends OpModalComponent implements AfterViewInit {
  public changed = false;

  public showClose = true;

  public selectedType:string;

  public buttonStyle:boolean;

  public availableTypes:TypeResource[];

  public type = '';

  public classes = '';

  @ViewChild('typeSelect', { static: true }) typeSelect:ElementRef;

  public text:any = {
    title: this.I18n.t('js.editor.macro.work_package_button.button'),
    none: this.I18n.t('js.label_none'),
    selected_type: this.I18n.t('js.editor.macro.work_package_button.type'),
    button_style: this.I18n.t('js.editor.macro.work_package_button.button_style'),
    button_style_hint: this.I18n.t('js.editor.macro.work_package_button.button_style_hint'),
    button_save: this.I18n.t('js.button_save'),
    button_cancel: this.I18n.t('js.button_cancel'),
    close_popup: this.I18n.t('js.close_popup_title'),
  };

  constructor(readonly elementRef:ElementRef,
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    protected currentProject:CurrentProjectService,
    protected apiV3Service:ApiV3Service,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService) {
    super(locals, cdRef, elementRef);
    this.selectedType = this.type = this.locals.type;
    this.classes = this.locals.classes;
    this.buttonStyle = this.classes === 'button';

    this
      .apiV3Service
      .withOptionalProject(this.currentProject.identifier)
      .work_packages
      .form
      .post({})
      .subscribe((form:FormResource) => {
        this.availableTypes = form.schema.type.allowedValues;
        this.cdRef.detectChanges();
      });
  }

  public applyAndClose(evt:Event):void {
    this.changed = true;
    this.classes = this.buttonStyle ? 'button' : '';
    this.type = this.selectedType;
    this.closeMe(evt);
  }

  ngAfterViewInit():void {
    this.typeSelect.nativeElement.focus();
  }
}
