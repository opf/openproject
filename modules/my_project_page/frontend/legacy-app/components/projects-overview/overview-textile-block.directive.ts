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
import {PluginContextService} from "core-app/services/plugin-context.service";

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
              public pluginContext:PluginContextService) {
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
    return false;
  }

  /**
   * Remove this block
   */
  public remove(evt:Event) {
    evt.preventDefault();

    if (this.$window.confirm(I18n.t('js.text_are_you_sure'))) {
      this.$element.remove();
    }

    return false;
  }

  /**
   * Save changes from the textile block
   */
  public submitForm(evt:JQueryEventObject) {
    var form = this.$element.find('.textile-form');

    // Update change event
    form.trigger('change.ckeditor');

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
      this.pluginContext.context!.services.notifications.addSuccess(I18n.t('js.notice_successful_update'));
      this.layoutCtrl.updateBlock(this.blockName, response);
      this.toggleEditForm();
    }).fail((error) => {
      deferred.reject();
      this.$timeout(() => {
        this.pluginContext.context!.services.notifications.addError(
          I18n.t('js.notification_update_block_failed') + ' ' + error.responseText
        );
      });
    });

    evt.preventDefault();
    return false;
  }
}

function overviewTextileBlock($compile:any):any {
  return {
    restrict: 'E',
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

        scope.$ctrl.layoutCtrl = scope.$parent.$ctrl;

        transclude(scope, (clone:any) => {
          let original = jQuery(`#block_${scope.$ctrl.blockName}`);
          element.append($compile(original)(scope));

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

angular.module('OpenProjectLegacy').directive('overviewTextileBlock', overviewTextileBlock);
