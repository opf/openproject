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

import {IDialogService} from 'ng-dialog';
import {opUiComponentsModule} from '../../../angular-modules';
import IAugmentedJQuery = angular.IAugmentedJQuery;

export class ModalWrapperController {
  private modalBody: string;
  public modal: any;
  public modalParams: any;
  public activationLinkId: string;

  public iframeSelector = '.iframe-target-wrapper';

  private modalOptions: any = {
    plain: true,
    closeByEscape: true,
    closeByDocument: false,
    className: 'ngdialog-theme-openproject'
  };

  constructor(protected $element:ng.IAugmentedJQuery,
              protected $scope:ng.IScope,
              protected $attrs: ng.IAttributes,
              protected ngDialog: IDialogService) {

    // Find activation link
    var activationLink = $element.find('.modal-wrapper--activation-link');
    if(this.activationLinkId) {
      activationLink = jQuery(this.activationLinkId);
    }

    // Set template from wrapped element
    const wrappedElement = $element.find('.modal-wrapper--content');
    this.modalBody = wrappedElement.html();

    if ($attrs['iframeUrl']) {
      this.appendIframe($attrs['iframeUrl']);
    }

    angular.extend(this.modalOptions, this.modalParams || {});
    this.modalOptions.template = this.modalBody;

    if (!!$attrs['initialize']) {
      this.initialize();
    }
    else {
      activationLink.click(() => this.initialize());
    }
  }

  public initialize() {
    this.modal = this.ngDialog.open(this.modalOptions);
  }

  private appendIframe(url:string) {
    let subdom = angular.element(this.modalBody);
    let iframe = angular.element('<iframe frameborder="0" height="282" allowfullscreen>></iframe>');
    iframe.attr('src', url);

    subdom.find(this.iframeSelector).append(iframe);;

    this.modalBody = subdom.html();
  }
}

function modalWrapper() {
  return {
    restrict: 'E',
    scope: {
      modalParams: '=',
      activationLinkId: '=?'
    },
    controller: ModalWrapperController,
    controllerAs: '$ctrl',
    bindToController: true,
  };
}

opUiComponentsModule.directive('modalWrapper', modalWrapper);
