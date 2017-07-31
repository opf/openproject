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
import {opUiComponentsModule} from '../../../angular-modules';
import {HelpTextResourceInterface} from '../../api/api-v3/hal-resources/help-text-resource.service';
import {HelpTextDmService} from '../../api/api-v3/hal-resource-dms/help-text-dm.service';
import {AttributeHelpTextsService} from './attribute-help-text.service';

export class AttributeHelpTextController {
  // Attribute to show help text for
  public attribute:string;
  public optionaltitle?:string;
  // Scope to search for
  public attributeScope:string;
  // Load single id entry if given
  public helpTextId?:string;
  public additionalLabel?:string;

  public exists:boolean = false;
  public text:any;

  constructor(protected $element:IAugmentedJQuery,
              protected $scope:angular.IScope,
              protected helpTextDm:HelpTextDmService,
              protected attributeHelpTexts:AttributeHelpTextsService,
              protected $q:angular.IQService,
              protected ngDialog:IDialogService,
              protected I18n:op.I18n) {

    this.text = {
      open_dialog: I18n.t('js.help_texts.show_modal')
    };

    this.$scope.text = {
      'edit': I18n.t('js.button_edit'),
      'close': I18n.t('js.button_close')
    };

    // Prevent event bubbling so that we can e.g.
    // avoid it bubbling to the newly focused element handler on close.
    this.$scope.close = (event:JQueryEventObject) => {
      event.preventDefault();
      event.stopPropagation();

      this.ngDialog.close('');
    };

    if (this.helpTextId) {
      this.exists = true;
    } else {
      // Need to load the promise to find out if the attribute exists
      this.load().then((resource) => {
        this.exists = !!resource;
        return resource;
      });
    }
  }

  public handleClick() {
    this.load().then((resource) => {
      this.renderModal(resource);
    });
  }

  private load() {
    if (this.helpTextId) {
      return this.helpTextDm.load(this.helpTextId);
    } else {
      return this.attributeHelpTexts.require(this.attribute, this.attributeScope);
    }
  }

  private renderModal(resource:HelpTextResourceInterface) {
    this.$scope.resource = resource;
    this.ngDialog.open({
      closeByEscape: true,
      showClose: false,
      closeByDocument: true,
      scope: <IDialogScope> this.$scope,
      template: '/components/common/help-texts/help-text.modal.html',
      className: 'ngdialog-theme-openproject -light -wide'
    });
  }
}

opUiComponentsModule.component('attributeHelpText', {
  templateUrl: '/components/common/help-texts/help-text.directive.html',
  controller: AttributeHelpTextController,
  controllerAs: '$ctrl',
  bindings: {
    attribute: '<',
    attributeScope: '@',
    helpTextId: '@?',
    additionalLabel: '@?'
  }
});
