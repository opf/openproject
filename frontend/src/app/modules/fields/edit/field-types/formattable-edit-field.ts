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

import {ICkeditorStatic} from "core-components/ckeditor/op-ckeditor-form.component";
import {EditField} from "core-app/modules/fields/edit/edit.field.module";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {FormattableEditFieldComponent} from "core-app/modules/fields/edit/field-types/formattable-edit-field.component";

declare global {
  interface Window {
    OPBalloonEditor:ICkeditorStatic;
    OPClassicEditor:ICkeditorStatic;
  }
}

export class FormattableEditField extends EditField {
  readonly pathHelper:PathHelperService = this.$injector.get(PathHelperService);

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
    const element = container.querySelector('.op-ckeditor-element') as HTMLElement;

    window.OPBalloonEditor
      .create(element, {
        openProject: {
          context: this.resource,
          helpURL: this.pathHelper.textFormattingHelp(),
          element: element,
          pluginContext: window.OpenProject.pluginContext.value
        }
      })
      .then((editor:any) => {
        this.ckeditor = editor;
        if (this.rawValue) {
          this.reset();
        }

        setTimeout(() => editor.editing.view.focus());

        this.updateValueOnEditorChange(editor);
      })
      .catch((error:any) => {
        console.error(error);
      });
  }

  private updateValueOnEditorChange(editor:any) {
    editor.model.document.on('change', () => {
      this.rawValue = this.ckeditor.getData();
    } );
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
