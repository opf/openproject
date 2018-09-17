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

import {Component, ViewChild} from "@angular/core";
import {EditFieldComponent} from "core-app/modules/fields/edit/edit-field.component";
import {FormattableEditField} from "core-app/modules/fields/edit/field-types/formattable-edit-field";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {ICKEditorContext, ICKEditorInstance} from "core-app/modules/common/ckeditor/ckeditor-setup.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {OpCkeditorComponent} from "core-app/modules/common/ckeditor/op-ckeditor.component";

@Component({
  template: `
    <div class="textarea-wrapper">
      <div class="op-ckeditor--wrapper op-ckeditor-element">
        <op-ckeditor [context]="context"
                     [content]="field.rawValue || ''"
                     (onContentChange)="onContentChange($event)"
                     (onInitialized)="onCkeditorSetup($event)"
                     [ckEditorType]="editorType">
        </op-ckeditor>
      </div>
      <edit-field-controls *ngIf="!handler.inEditMode"
                           [fieldController]="handler"
                           (onSave)="handleUserSubmit()"
                           (onCancel)="handler.handleUserCancel()"
                           [saveTitle]="field.text.save"
                           [cancelTitle]="field.text.cancel">
      </edit-field-controls>
    </div>
  `
})
export class FormattableEditFieldComponent extends EditFieldComponent {
  public field:FormattableEditField;
  private readonly pathHelper:PathHelperService = this.injector.get(PathHelperService);
  private readonly Notifications = this.injector.get(NotificationsService);

  @ViewChild(OpCkeditorComponent) instance:OpCkeditorComponent;

  public onContentChange(value:string) {
    this.field.rawValue = value;
  }

  public onCkeditorSetup(editor:ICKEditorInstance) {
    if (!this.resource.isNew) {
      setTimeout(() => editor.editing.view.focus());
    }
  }

  public handleUserSubmit() {
    this.instance
      .getTransformedContent()
      .then((value:string) => {
        this.field.rawValue = value;
        this.handler.handleUserSubmit();
      });

    return false;
  }

  public get context():ICKEditorContext {
    return {
      resource: this.resource,
      macros: 'none' as 'none',
      previewContext: this.previewContext
    };
  }

  public get editorType() {
    if (this.field.name === 'description') {
      return 'full';
    } else {
      return 'constrained';
    }
  }

  public get previewContext() {
    if (this.resource.isNew && this.resource.project) {
      return this.resource.project.href;
    } else if (!this.resource.isNew) {
      return this.pathHelper.api.v3.work_packages.id(this.resource.id).path;
    }
  }
}
