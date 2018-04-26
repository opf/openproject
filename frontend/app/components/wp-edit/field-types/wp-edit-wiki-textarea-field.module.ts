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

import {EditField} from '../wp-edit-field/wp-edit-field.module';
import {TextileService} from './../../common/textile/textile-service';
import {AutoCompleteHelperService} from 'core-components/common/autocomplete/auto-complete-helper.service';
import {ConfigurationService} from 'core-components/common/config/configuration.service';
import {
  $sceToken,
  AutoCompleteHelperServiceToken,
  I18nToken,
  TextileServiceToken
} from 'core-app/angular4-transition-utils';

export class WikiTextareaEditField extends EditField {

  // Template
  public template:string;

  // Dependencies
  readonly $sce:ng.ISCEService = this.$injector.get($sceToken);
  readonly textileService:TextileService = this.$injector.get(TextileServiceToken);
  readonly I18n:op.I18n = this.$injector.get(I18nToken);
  readonly AutoCompleteHelper:AutoCompleteHelperService = this.$injector.get(
    AutoCompleteHelperServiceToken);
  readonly ConfigurationService:ConfigurationService = this.$injector.get(ConfigurationService);

  // Values used in template
  public isBusy:boolean = false;
  public isPreview:boolean = false;
  public previewHtml:string;
  public text:Object;
  public wysiwig:boolean;

  // CKEditor instance
  public ckeditor:any;

  protected initialize() {
    const configurationService:ConfigurationService = this.$injector.get(ConfigurationService);
    this.wysiwig = configurationService.textFormat() === 'markdown';
    this.setupTemplate();

    this.text = {
      attachmentLabel: this.I18n.t('js.label_formattable_attachment_hint'),
      save: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
      cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name })
    };
  }

  public setupTemplate() {
    if (this.wysiwig) {
      this.template = '/components/wp-edit/field-types/wp-edit-markdown-field.directive.html';
    } else {
      this.template = '/components/wp-edit/field-types/wp-edit-wiki-textarea-field.directive.html';
    }
  }

  public onSubmit() {
    if (this.wysiwig && this.ckeditor) {
      this.rawValue = this.ckeditor.getData();
    }
  }

  public $onInit(container:JQuery) {
    if (this.wysiwig) {
      this.setupMarkdownEditor(container);
    } else {
      jQuery('body').css('background', 'red !important');
    }
  }

  public setupMarkdownEditor(container:JQuery) {
    const element = container.find('.op-ckeditor-element');
    window.OPBalloonEditor
      .create(element[0])
      .then((editor:any) => {
        editor.config['openProject'] = {
          context: this.resource,
          element: element
        };

        this.ckeditor = editor;
        if (this.rawValue) {
          this.reset();
        }

        this.AutoCompleteHelper.enableTextareaAutoCompletion(element, this.resource.project.id);

        setTimeout(() => editor.editing.view.focus());
      })
      .catch((error:any) => {
        console.error(error);
      });
  }

  public reset() {
    if (this.wysiwig) {
      this.ckeditor.setData(this.rawValue);
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
    this.value = { raw: val };
  }

  public get isFormattable() {
    return true;
  }

  public isEmpty():boolean {
    if (this.wysiwig && this.ckeditor) {
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

  public togglePreview() {
    this.isPreview = !this.isPreview;
    this.previewHtml = '';

    if (!this.rawValue) {
      return;
    }

    if (this.isPreview) {
      this.isBusy = true;
      this.changeset.getForm().then((form:any) => {
        const link = form.previewMarkup.$link;

        this.textileService.render(link, this.rawValue)
          .then((result:any) => {
            this.isBusy = false;
            this.previewHtml = this.$sce.trustAsHtml(result.data);
          })
          .catch(() => {
            this.isBusy = false;
          });
      });
    }
  }
}
