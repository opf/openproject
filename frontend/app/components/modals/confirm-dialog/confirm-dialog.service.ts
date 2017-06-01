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

export interface ConfirmDialogOptions {
  text:{
    title:string;
    text:string;
    button_continue?:string;
    button_cancel?:string;
  };
  closeByEscape?:boolean;
  showClose?:boolean;
  closeByDocument?:boolean;
}

export class ConfirmDialogService {

  private defaultTexts:any;

  constructor(protected $rootScope:ng.IRootScopeService,
              protected $q:angular.IQService,
              protected ngDialog:IDialogService,
              protected I18n:op.I18n) {

    this.defaultTexts = {
      title: I18n.t('js.modals.form_submit.title'),
      text: I18n.t('js.modals.form_submit.text'),
      button_continue: I18n.t('js.button_continue'),
      button_cancel: I18n.t('js.button_cancel')
    };
  }

  /**
   * Confirm an action with an ng dialog with the given options
   */
  public confirm(options:ConfirmDialogOptions):ng.IPromise<void> {
    const deferred = this.$q.defer<void>();
    const scope = this.$rootScope.$new();
    let dialog:IDialogOpenResult;

    scope.text = options.text;
    _.defaults(scope.text, this.defaultTexts);
    scope.confirmAndClose = () => {
      scope.confirmed = true;
      dialog.close();
    };

    scope.cancel = () => {
      scope.confirmed = false;
      dialog.close();
    };


    dialog = this.ngDialog.open({
      closeByEscape: _.defaultTo(options.closeByDocument, true),
      showClose: _.defaultTo(options.closeByDocument, true),
      scope: <IDialogScope> scope,
      template: '/components/modals/confirm-dialog/confirm-dialog.modal.html',
      className: 'ngdialog-theme-openproject',
      preCloseCallback: () => {
        if (scope.confirmed) {
          deferred.resolve();
        } else {
          deferred.reject();
        }
        return true;
      }
    });

    return deferred.promise;
  }
}

angular
  .module('openproject.uiComponents')
  .service('confirmDialog', ConfirmDialogService);
