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

import {Field} from "../wp-edit-field/wp-edit-field.module";
import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";

export class WikiTextareaField extends Field {

  // Template
  public template:string = '/components/wp-edit/field-types/wp-edit-wiki-textarea-field.directive.html';

  // Dependencies
  protected $sce:ng.ISCEService = <ng.ISCEService> this.$injector.get("$sce");
  protected TextileService:ng.IServiceProvider = <ng.ISCEProvider> this.$injector.get("TextileService");
  protected $timeout:ng.ITimeoutService = <ng.ITimeoutService> this.$injector.get("$timeout");
  protected I18n:op.I18n = <op.I18n> this.$injector.get("I18n");

  // wp resource
  protected workPackage:WorkPackageResource;

  // Values used in template
  public fieldVal:any;
  public isBusy:boolean = false;
  public isPreview:boolean = false;
  public previewHtml:string;

  public text: Object;


  constructor(workPackage, fieldName, schema) {
    super(workPackage, fieldName, schema);

    this.fieldVal = workPackage[fieldName];
    this.workPackage = workPackage;
    this.text = {
      saveTitle: this.I18n.t('js.inplace.button_save', { attribute: this.schema.name }),
      cancelTitle: this.I18n.t('js.inplace.button_cancel', { attribute: this.schema.name })
    };
  }

  public isEmpty(): boolean {
    return !(this.value && this.value.raw);
  }

  public submitUnlessInPreview(form) {
    this.$timeout(() => {
      if (!this.isPreview) {
        form.submit();
      }
    });
  }

  public togglePreview() {
    this.isPreview = !this.isPreview;
    this.previewHtml = '';

    if (this.isPreview) {
      this.isBusy = true;
      this.workPackage.getForm().then(form => {
        var previewLink = form.$links.previewMarkup.$route;
        previewLink
          .customPOST(this.fieldVal.raw, void 0, void 0, {'Content-Type': 'text/plain; charset=UTF-8'})
          .then(result => {
            this.previewHtml = this.$sce.trustAsHtml(result);
            this.isBusy = false;
          });
      });
    }
  }
}
