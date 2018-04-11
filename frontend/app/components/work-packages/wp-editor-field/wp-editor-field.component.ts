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

import {opWorkPackagesModule} from './../../../angular-modules';
import {WorkPackageChangeset} from './../../wp-edit-form/work-package-changeset';
import {WorkPackageResourceInterface} from './../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageEditFieldGroupComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field-group.directive';

export class WorkPackageEditorFieldController {
  public wpEditFieldGroup:WorkPackageEditFieldGroupComponent;
  public workPackage:WorkPackageResourceInterface;
  public attribute:string;
  public wrapperClasses:string;

  // Which template to include
  public format:string;
  public ckeditor:any;

  // Remember if the user changed
  public changed:boolean = false;
  public inFlight:boolean = false;

  public text:any;


  constructor(protected $element:ng.IAugmentedJQuery,
              protected $timeout:ng.ITimeoutService,
              protected ConfigurationService:any,
              protected I18n:op.I18n) {

    this.text = {
      saveTitle: 'Save',
      cancelTitle: 'Cancel'
    };

    // if(ConfigurationService.text_formatting ==  'markdown') {
      this.format = 'markdown';
    // } else {
    // }

  }

  public $onInit() {
    const element = this.$element.find('.op-ckeditor-element');
    (window as any).BalloonEditor
      .create(element[0])
      .then((editor:any) => {
        this.ckeditor = editor;
        if (this.rawValue) {
          this.reset();
        }
      })
      .catch((error:any) => {
        console.error(error);
      });
  }

  public submit() {
    this.inFlight = true;
    this.value = this.ckeditor.getData();
    this.wpEditFieldGroup.saveWorkPackage().then(() => {
      this.reset();
    })
    .catch(() => {
      this.reset();
    });
  }

  public reset() {
    this.ckeditor.setData(this.rawValue);
    this.$timeout(() => {
      this.changed = false;
      this.inFlight = false;
    });
  }

  public get isInitialized() {
    return !!this.ckeditor;
  }

  public get value() {
    return this.changeset.value(this.attribute);
  }

  public get rawValue() {
    if (this.value && this.value.raw) {
      return this.value.raw;
    } else {
      return '';
    }
  }

  public set value(value:any) {
    this.changeset.setValue(this.attribute, { raw: value });
  }

  public get changeset():WorkPackageChangeset {
    return this.wpEditFieldGroup.form.changeset;
  }
}

opWorkPackagesModule.component('wpEditorField', {
  templateUrl: '/components/work-packages/wp-editor-field/wp-editor-field.component.html',
  controller: WorkPackageEditorFieldController,
  require: {
    wpEditFieldGroup: '^wpEditFieldGroup'
  },
  controllerAs: '$ctrl',
  bindings: {
    workPackage: '<',
    attribute: '<',
    wrapperClasses: '@'
  }
});
