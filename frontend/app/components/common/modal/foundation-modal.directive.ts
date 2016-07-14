// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
// Heavily borrows from foundation-apps ModalFactory. Copyright (c) 2014 ZURB, inc.
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

import {FoundationModalContainerController} from './foundation-modal-container.directive';
export class FoundationModalController {
  public id:string;
  public containerCtrl:FoundationModalContainerController;
  public attached:boolean = false;
  public destroyed:boolean = false;
  public modalElement:ng.IAugmentedJQuery;
  public modalScope:any;
  public template:string;

  constructor(protected $element:ng.IAugmentedJQuery,
              protected $attrs:ng.IAttributes,
              protected $scope:ng.IScope,
              protected $rootScope:ng.IScope,
              protected $q:ng.IQService,
              protected $compile:ng.ICompileService,
              protected $timeout:ng.ITimeoutService,
              protected FoundationApi) {
    // User inner html as template
    this.template = $element.html();

    // Use or generate random ID
    this.id = $attrs['id'] || FoundationApi.generateUuid();

    if (document.getElementById(this.id)) {
      throw 'Error: Modal ID ' + this.id + ' already exists.';
    }

    // Build the modalElement to insert
    this.modalScope = $rootScope.$new();
    this.modalScope.$ctrl = this;
    this.modalScope.active = false;
    this.modalElement = angular.element('<zf-modal id="' + this.id + '">' + this.template + '</zf-modal>');

    // Set some defaults
    this.modalElement.attr('overlay-close', 'false');

    // Activate modal
    this.activate();
  }

  public activate() {
    this.$timeout(() => {
      this.init();
      this.FoundationApi.publish(this.id, 'show');
    }, 0, false);
  }

  public deactivate() {
    this.$timeout(() => {
      this.init();
      this.FoundationApi.publish(this.id, 'hide');
    }, 0, false);
  }

  public toggle() {
    this.$timeout(() => {
      this.init();
      this.FoundationApi.publish(this.id, 'toggle');
    }, 0, false);
  }

  protected init() {
    if (!this.attached) {
      angular.element(document.body).append(this.modalElement);

      this.$compile(this.modalElement)(this.modalScope);
      this.modalScope.active = true;
      this.attached = true;
    }
  }

  public close() {
    // Remove modal element
    this.deactivate();
    this.modalElement.remove();
    this.destroyed = true;
    this.FoundationApi.unsubscribe(this.id);

    // Close container
    this.containerCtrl.hide();
  }
}


function foundationModal(ModalFactory) {
  var foundationModalLink = function (scope,
                                      element,
                                      attr,
                                      containerCtrl: FoundationModalContainerController) {

    scope.$ctrl.containerCtrl = containerCtrl;
  };

  return {
    restrict: 'A',
    require: '^foundationModalContainer',
    scope: {
      modalClass: '@',
    },
    link: foundationModalLink,
    controller: FoundationModalController,
    controllerAs: '$ctrl',
  };
}

angular
  .module('openproject.uiComponents')
  .directive('foundationModal', foundationModal);
