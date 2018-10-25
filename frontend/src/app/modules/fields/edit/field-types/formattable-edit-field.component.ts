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

import {Component, OnInit, ViewChild} from "@angular/core";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {EditFieldComponent} from "core-app/modules/fields/edit/edit-field.component";
import {OpCkeditorComponent} from "core-app/modules/common/ckeditor/op-ckeditor.component";
import {ICKEditorContext, ICKEditorInstance} from "core-app/modules/common/ckeditor/ckeditor-setup.service";
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';

export const formattableFieldTemplate = `
    <div class="textarea-wrapper">
      <div class="op-ckeditor--wrapper op-ckeditor-element">
        <op-ckeditor [context]="ckEditorContext"
                     [content]="rawValue"
                     (onContentChange)="onContentChange($event)"
                     (onInitializationFailed)="initializationError = true"
                     (onInitialized)="onCkeditorSetup($event)"
                     [ckEditorType]="editorType">
        </op-ckeditor>
      </div>
      <edit-field-controls *ngIf="!(handler.inEditMode || initializationError)"
                           [fieldController]="field"
                           (onSave)="handler.handleUserSubmit()"
                           (onCancel)="handler.handleUserCancel()"
                           [saveTitle]="text.save"
                           [cancelTitle]="text.cancel">
      </edit-field-controls>
    </div>
`

@Component({
  template: formattableFieldTemplate
})
export class FormattableEditFieldComponent extends EditFieldComponent implements OnInit {
  readonly pathHelper:PathHelperService = this.$injector.get(PathHelperService);

  public readonly field = this;

  // Detect when inner component could not be initalized
  public initializationError = false;

  @ViewChild(OpCkeditorComponent) instance:OpCkeditorComponent;

  // Values used in template
  public isPreview:boolean = false;
  public previewHtml:string = '';
  public text = {
    attachmentLabel: this.I18n.t('js.label_formattable_attachment_hint'),
    save: this.I18n.t('js.inplace.button_save', {attribute: this.schema.name}),
    cancel: this.I18n.t('js.inplace.button_cancel', {attribute: this.schema.name})
  };

  ngOnInit() {
    this.handler.registerOnSubmit(() => this.getCurrentValue());
  }

  public onCkeditorSetup(editor:ICKEditorInstance) {
    if (!this.resource.isNew) {
      setTimeout(() => editor.editing.view.focus());
    }
  }

  public getCurrentValue():Promise<void> {
    return this.instance
      .getTransformedContent()
      .then((val) => {
        this.rawValue = val;
      });
  }

  public onContentChange(value:string) {
    this.rawValue = value;
  }

  public handleUserSubmit() {
    this.getCurrentValue()
      .then(() => {
        this.handler.handleUserSubmit();
      });

    return false;
  }

  public get ckEditorContext():ICKEditorContext {
    return {
      resource: this.resource,
      macros: 'none' as 'none',
      previewContext: this.previewContext
    };
  }

  public get editorType() {
    if (this.name === 'description') {
      return 'full';
    } else {
      return 'constrained';
    }
  }

  private get previewContext() {
    if (this.resource.isNew && this.resource.project) {
      return this.resource.project.href;
    } else if (!this.resource.isNew) {
      return this.pathHelper.api.v3.work_packages.id(this.resource.id).path;
    }
  }

  public reset() {
    if (this.instance) {
      this.instance.content = this.rawValue;
    }
  }

  public get rawValue() {
    if (this.value && this.value.raw) {
      return this.value.raw;
    } else {
      return '';
    }
  }

  public set rawValue(val:string) {
    this.value = {raw: val};
  }

  public isEmpty():boolean {
    return !(this.value && this.value.raw);
  }

  public get isFormattable() {
    return true;
  }
}
