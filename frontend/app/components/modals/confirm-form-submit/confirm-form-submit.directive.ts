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
import { IDialogOpenResult, IDialogService } from 'ng-dialog';
import {IDialogScope} from 'ng-dialog';

export class ConfirmFormSubmitController {

  // Allow original form submission after dialog was closed
  private confirmed = false;
  private dialog: IDialogOpenResult;

  constructor(protected $element:IAugmentedJQuery,
              protected $scope:angular.IScope,
              protected $http:angular.IHttpService,
              protected $q:angular.IQService,
              protected ngDialog:IDialogService,
              protected I18n:op.I18n) {

    this.$scope['text'] = {
      title: I18n.t('js.modals.form_submit.title'),
      text: I18n.t('js.modals.form_submit.text'),
      button_continue: I18n.t('js.button_continue'),
      button_cancel: I18n.t('js.button_cancel')
    };

    this.$scope['confirmAndClose'] = () => {
      this.confirmed = true;
      this.dialog.close();
    };

    $element.on('submit', (evt) => {
      if (!this.confirmed) {
        evt.preventDefault();
        this.openConfirmationDialog();
        return false;
      }

      return true;
    });
  }

  public openConfirmationDialog() {
    this.dialog = this.ngDialog.open({
      closeByEscape: true,
      showClose: true,
      closeByDocument: true,
      scope: <IDialogScope> this.$scope,
      template: '/components/modals/confirm-form-submit/confirm-form-submit.modal.html',
      className: 'ngdialog-theme-openproject',
      preCloseCallback: () => {
        if (this.confirmed) {
          this.$element.submit();
        }
        return true;
      }
    });
  }
}

function confirmFormSubmit() {
  return {
    restrict: 'AC',
    scope: {},
    bindToController: true,
    controller: ConfirmFormSubmitController,
    controllerAs: '$ctrl',
  };
}

angular
  .module('openproject.uiComponents')
  .directive('confirmFormSubmit', confirmFormSubmit);
