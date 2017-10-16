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
import {$injectFields} from '../../angular/angular-injector-bridge.functions';
import {TextileService} from './../../common/textile/textile-service';
import {WorkPackageEditFieldHandler} from 'core-components/wp-edit-form/work-package-edit-field-handler';

export class WikiTextareaEditField extends EditField {

  // Template
  public template:string = '/components/wp-edit/field-types/wp-edit-markdown-field.directive.html';

  // Dependencies
  protected $sce:ng.ISCEService;
  protected $http:ng.IHttpService;
  protected textileService:TextileService;
  protected $timeout:ng.ITimeoutService;
  protected I18n:op.I18n;

  // Values used in template
  public isBusy:boolean = false;
  public isPreview:boolean = false;
  public previewHtml:string;
  public text:Object;

  // CKEditor instance
  public ckeditor:any;

  protected initialize() {
    $injectFields(this, '$sce', '$http', 'textileService', '$timeout', 'I18n');

    this.text = {
      attachmentLabel: this.I18n.t('js.label_formattable_attachment_hint'),
      save: this.I18n.t('js.inplace.button_save', {attribute: this.schema.name}),
      cancel: this.I18n.t('js.inplace.button_cancel', {attribute: this.schema.name})
    };
  }

  public onSubmit() {
    if (this.ckeditor) {
      this.rawValue = this.ckeditor.getData();
    }
  }

  public get isInitialized() {
    return !!this.ckeditor;
  }

  public $onInit(container:JQuery) {
    const element = container.find('.op-ckeditor-element');
    (window as any).BalloonEditor
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

        element.focus();
      })
      .catch((error:any) => {
        console.error(error);
      });
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
    this.value = {raw: val};
  }

  public get isFormattable() {
    return true;
  }

  public isEmpty():boolean {
    if (this.isInitialized) {
      return this.ckeditor.getData() === '';
    } else {
      return !(this.value && this.value.raw);
    }
  }

  public submitUnlessInPreview(form:any) {
    this.$timeout(() => {
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
            this.previewHtml = this.$sce.trustAsHtml(result.data);
          })
          .finally(() => {
            this.isBusy = false;
          });
      });
    }
  }
}
