// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {Component} from "@angular/core";
import {EditFieldComponent} from "core-app/modules/fields/edit/edit-field.component";
import ExpressionService from "core-app/modules/common/xss/expression.service";
import {FormattableEditField} from "core-app/modules/fields/edit/field-types/formattable-edit-field";

@Component({
  template: `
    <div class="textarea-wrapper" ng-class="{'-preview': vm.field.isPreview}">
      <textarea
        style="min-height: 114px"
        class="focus-input wp-inline-edit--field inplace-edit--textarea -animated"
        name="value"
        *ngIf="!field.isPreview"
        [disabled]="field.isBusy || field.inFlight"
        [required]="field.required"
        [(ngModel)]="field.rawValue"
        [id]="handler.htmlId">
      </textarea>
      <div class="inplace-edit--preview"
           *ngIf="field.isPreview && !field.isBusy">
        <span [innerHTML]="unEscapedPreviewHtml"></span>
      </div>
      <div *ngIf="field.isFormattable && !field.isPreview"
           class="wp-edit-field-attachment-label">
        <span [textContent]="field.text.attachmentLabel"></span>
      </div>
      <edit-field-controls *ngIf="!handler.inEditMode"
                           [fieldController]="handler"
                           (onSave)="handler.handleUserSubmit()"
                           (onCancel)="handler.handleUserCancel()"
                           [saveTitle]="field.text.save"
                           [cancelTitle]="field.text.cancel">
      </edit-field-controls>
    </div>

  `
})
export class FormattableTextareaEditFieldComponent extends EditFieldComponent {
  readonly expressionService:ExpressionService = this.injector.get(ExpressionService);
  public field:FormattableEditField;

  public get unEscapedPreviewHtml() {
    return this.expressionService.unescape(this.field.previewHtml);
  }
}
