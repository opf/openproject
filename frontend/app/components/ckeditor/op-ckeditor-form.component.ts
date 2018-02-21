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

import IAugmentedJQuery = angular.IAugmentedJQuery;
import {IDialogService} from 'ng-dialog';
import {IDialogScope} from 'ng-dialog';
import {opUiComponentsModule} from '../../angular-modules';

export interface ICkeditorInstance {
  getData():string;
  setData(content:string):void;
}

export interface ICkeditorStatic {
  create(el:HTMLElement):Promise<ICkeditorInstance>;
}

declare global {
  interface Window {
    BalloonEditor:ICkeditorStatic;
    ClassicEditor:ICkeditorStatic;
  }
}

const ckEditorWrapperClass = 'op-ckeditor--wrapper';
const ckEditorReplacementClass = '__op_ckeditor_replacement_container';

export class OpCkeditorFormComponent {
  public textareaSelector:string;

  // Which template to include
  public ckeditor:any;
  public formElement:JQuery;
  public wrappedTextArea:JQuery;

  // Remember if the user changed
  public changed:boolean = false;
  public inFlight:boolean = false;

  public text:any;


  constructor(protected $element:ng.IAugmentedJQuery,
              protected $timeout:ng.ITimeoutService,
              protected ConfigurationService:any,
              protected I18n:op.I18n) {

  }

  public $onInit() {
    this.formElement = this.$element.closest('form');
    this.wrappedTextArea = this.formElement.find(this.textareaSelector);
    this.wrappedTextArea.hide();
    const wrapper = this.$element.find(`.${ckEditorReplacementClass}`);
    window.ClassicEditor
      .create(wrapper[0])
      .then(this.setup.bind(this))
      .catch((error:any) => {
        console.error(error);
      });
  }

  public $onDestroy() {
    this.formElement.off('submit.ckeditor');
  }

  public setup(editor:ICkeditorInstance) {
    this.ckeditor = editor;
    const rawValue = this.wrappedTextArea.val();

    if (rawValue) {
      editor.setData(rawValue);
    }

    // Listen for form submission to set textarea content
    this.formElement.on('submit.ckeditor', () => {
      const value = this.ckeditor.getData();
      this.wrappedTextArea.val(value);

      // Continue with submission
      return true;
    });
  }
}

opUiComponentsModule.component('opCkeditorForm', {
  template: `<div class="${ckEditorWrapperClass}"><div class="${ckEditorReplacementClass}"></div>`,
  controller: OpCkeditorFormComponent,
  controllerAs: '$ctrl',
  bindings: {
    textareaSelector: '@'
  }
});
