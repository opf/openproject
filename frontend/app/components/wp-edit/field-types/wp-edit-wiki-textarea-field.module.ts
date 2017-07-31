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
import {WorkPackageResource} from '../../api/api-v3/hal-resources/work-package-resource.service';

export class WikiTextareaEditField extends EditField {

  // Template
  public template:string = '/components/wp-edit/field-types/wp-edit-wiki-textarea-field.directive.html';

  // Dependencies
  protected $sce:ng.ISCEService = <ng.ISCEService> WikiTextareaEditField.$injector.get('$sce');
  protected $http:ng.IHttpService = <ng.IHttpService> WikiTextareaEditField.$injector.get('$http');
  protected TextileService:ng.IServiceProvider = <ng.ISCEProvider> WikiTextareaEditField.$injector.get('TextileService');
  protected $timeout:ng.ITimeoutService = <ng.ITimeoutService> WikiTextareaEditField.$injector.get('$timeout');
  protected I18n:op.I18n = <op.I18n> WikiTextareaEditField.$injector.get('I18n');

  // wp resource
  protected workPackage:WorkPackageResource;

  // Values used in template
  public fieldVal:any;
  public isBusy:boolean = false;
  public isPreview:boolean = false;
  public previewHtml:string;

  public text: Object;


  constructor(workPackage:WorkPackageResource, fieldName:string, schema:op.FieldSchema) {
    super(workPackage, fieldName, schema);

    this.fieldVal = workPackage[fieldName];
    this.workPackage = workPackage;
    this.text = {
      attachmentLabel: this.I18n.t('js.label_formattable_attachment_hint'),
      save: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
      cancel: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name })
    };
  }

  public get isFormattable() {
    return true;
  }

  public isEmpty(): boolean {
    return !(this.value && this.value.raw);
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

    if (!this.fieldVal.raw) {
      return;
    }

    if (this.isPreview) {
      this.isBusy = true;
      this.workPackage.getForm().then((form:any) => {
        const link = form.previewMarkup.$link;
        this.$http({
          method: link.method,
          url: link.href,
          data: this.fieldVal.raw,
          headers: {'Content-Type': 'text/plain; charset=UTF-8'}
        })
          .then(result => {
            this.previewHtml = this.$sce.trustAsHtml(result.data);
          })
          .finally(() => {
            this.isBusy = false;
          });
      });
    }
  }
}
