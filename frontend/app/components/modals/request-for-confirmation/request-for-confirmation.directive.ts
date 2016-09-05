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

export class RequestForConfirmationController {

  // Allow original form submission after dialog was closed
  private passwordConfirmed = false;

  constructor(protected $element:IAugmentedJQuery,
              protected $scope:angular.IScope,
              protected $http:angular.IHttpService,
              protected $q:angular.IQService,
              protected ngDialog:IDialogService,
              protected I18n:op.I18n) {

    this.$scope['text'] = {
      title_confirmation: I18n.t('js.password_confirmation.title'),
      field_description: I18n.t('js.password_confirmation.field_description'),
      confirm_button: I18n.t('js.button_confirm'),
      password: I18n.t('js.label_password')
    };

    this.$scope['dialog'] = {
      password_value: ''
    };

    $element.submit((evt) => {
      if (!this.passwordConfirmed) {
        evt.preventDefault();
        this.openConfirmationDialog();
      }
    });
  }

  public openConfirmationDialog() {
    this.ngDialog.open({
      closeByEscape: false,
      showClose: false,
      closeByDocument: false,
      scope: <IDialogScope> this.$scope,
      template: '/components/modals/request-for-confirmation/request-for-confirmation.modal.html',
      className: 'ngdialog-theme-openproject',
      preCloseCallback: () => {
        this.appendPassword();
        this.$element.submit();
        return true;
      }
    });
  }

  /**
   * Post the confirmation to the endpoint
   */
  private appendPassword() {
    angular.element('<input>').attr({
      type: 'hidden',
      name: '_password_confirmation',
      value: this.$scope['dialog'].password_value
    }).appendTo(this.$element);
    this.passwordConfirmed = true;
  }
}

function requestForConfirmation() {
  return {
    restrict: 'AC',
    scope: {},
    bindToController: true,
    controller: RequestForConfirmationController,
    controllerAs: '$ctrl',
  };
}

angular
  .module('openproject.uiComponents')
  .directive('requestForConfirmation', requestForConfirmation);
