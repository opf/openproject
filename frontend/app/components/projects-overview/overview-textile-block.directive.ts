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

import {ProjectsOverviewController} from './overview-page-layout.directive';
export class OverviewTextileBlockController {

  public layoutCtrl:ProjectsOverviewController;

  // Waiting indicator
  public loadingIndicator:ng.IPromise<any>;

  // Block name
  public blockName:string;

  // Returned from backend if this is a newly added block
  public newBlock:boolean;

  // Current state of edit form showing
  public formVisible:boolean = false;

  constructor(public $element:ng.IAugmentedJQuery,
              public $timeout:ng.ITimeoutService,
              public $window:ng.IWindowService,
              public $q:ng.IQService,
              public I18n:op.I18n,
              public NotificationsService:any) {
  }

  public initialize() {
    if (this.newBlock) {
      this.toggleEditForm(true);
    }
  }

  public get editing() {
    return !!this.layoutCtrl;
  }

  public toggleEditForm(state?:boolean) {
    if (state === undefined) {
      state = !this.formVisible;
    }

    this.formVisible = state;
  }

  /**
   * Remove this block
   */
  public remove() {
    if (this.$window.confirm(this.I18n.t('js.text_are_you_sure'))) {
      this.$element.remove();
    }
  }

  /**
   * Save changes from the textile block
   */
  public submitForm(evt:JQueryEventObject) {
    var form = this.$element.find('.textile-form');
    var formData = new FormData(form[0] as HTMLFormElement);

    // $http fails to serialize the formData correctly,
    // even when forcing the content-type.
    var deferred = this.$q.defer();
    this.loadingIndicator = deferred.promise;
    jQuery.ajax({
      url: form.attr('action'),
      method: 'PUT',
      data: formData,
      cache: false,
      contentType: false,
      processData: false
    }).done((response) => {
      deferred.resolve();
      this.$timeout(() => {
        this.NotificationsService.addSuccess(this.I18n.t('js.notice_successful_update'));
      });
      this.layoutCtrl.updateBlock(this.blockName, response);
      this.layoutCtrl.updateAttachments();
    }).fail((error) => {
      deferred.reject();
      this.$timeout(() => {
        this.NotificationsService.addError(
          this.I18n.t('js.notification_update_block_failed') + ' ' + error.responseText
        );
      });
    });

    evt.preventDefault();
    return false;
  }
}

function overviewTextileBlock():any {
  return {
    restrict: 'EA',
    scope: {
      newBlock: '=?',
      blockName: '@'
    },
    transclude: true,
    compile: function() {
      return function(
        scope:any,
        element:ng.IAugmentedJQuery,
        attrs:ng.IAttributes,
        ctrl:any,
        transclude:any) {
        scope.$ctrl.layoutCtrl = ctrl;
        transclude(scope, (clone:any) => {
          element.append(clone);
          scope.$ctrl.initialize();
        });
      };
    },
    require: '?^overviewPageLayout',
    controller: OverviewTextileBlockController,
    bindToController: true,
    controllerAs: '$ctrl'
  };
}

angular.module('openproject').directive('overviewTextileBlock', overviewTextileBlock);
