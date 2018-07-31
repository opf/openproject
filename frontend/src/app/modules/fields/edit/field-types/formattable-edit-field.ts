// -- copyright
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

import {EditField} from "core-app/modules/fields/edit/edit.field.module";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {FormattableEditFieldComponent} from "core-app/modules/fields/edit/field-types/formattable-edit-field.component";
import {
  CKEditorSetupService,
  ICKEditorInstance,
  ICKEditorStatic
} from "core-components/ckeditor/ckeditor-setup.service";

declare global {
  interface Window {
    OPBalloonEditor:ICKEditorStatic;
    OPClassicEditor:ICKEditorStatic;
  }
}

export class FormattableEditField extends EditField {
  readonly pathHelper:PathHelperService = this.$injector.get(PathHelperService);
  readonly ckEditorSetup:CKEditorSetupService = this.$injector.get(CKEditorSetupService);

  // Values used in template
  public isBusy:boolean = false;
  public isPreview:boolean = false;
  public previewHtml:string = '';
  public text = {
    attachmentLabel: this.I18n.t('js.label_formattable_attachment_hint'),
    save: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
    cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name })
  };

  // CKEditor instance
  public ckeditor:any;

  public get component() {
    return FormattableEditFieldComponent;
  }

  public $onInit(container:HTMLElement) {
    this.setupMarkdownEditor(container);
  }

  public setupMarkdownEditor(container:HTMLElement) {
    const element = container.querySelector('.op-ckeditor-source-element') as HTMLElement;

    const context = { resource: this.resource,
                      previewContext: this.previewContext };

    this.ckEditorSetup
      .create(this.editorType,
              element,
              context)
      .then((editor:ICKEditorInstance) => {
        this.ckeditor = editor;
        if (!this.resource.isNew) {
          setTimeout(() => editor.editing.view.focus());
        }

        this.updateValueOnEditorChange(editor);
      });
  }

  private updateValueOnEditorChange(editor:any) {
    editor.model.document.on('change', () => {
      this.rawValue = this.ckeditor.getData();
    } );
  }

  private get editorType() {
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
    this.ckeditor.setData(this.rawValue);
  }

  public get rawValue() {
    if (this.value && this.value.raw) {
      return this.value.raw;
    } else {
      return '';
    }
  }

  public set rawValue(val:string) {
    this.value = { raw: val };
  }

  public get isFormattable() {
    return true;
  }

  public isEmpty():boolean {
    if (this.ckeditor) {
      return this.ckeditor.getData() === '';
    } else {
      return !(this.value && this.value.raw);
    }
  }

  public submitUnlessInPreview(form:any) {
    setTimeout(() => {
      if (!this.isPreview) {
        form.submit();
      }
    });
  }
}
