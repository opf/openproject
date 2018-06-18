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

import {openprojectLegacyModule} from "../../../openproject-legacy-app";

export class ModalWrapperController {
  public activationLinkId:string;
  public iframeSelector = '.iframe-target-wrapper';

  private modalBody:string;
  public modalClassName = 'ngdialog-theme-openproject';

  protected opModalService:any;
  protected dynamicContentModal:any;

  constructor(protected $element:ng.IAugmentedJQuery,
              protected $attrs:ng.IAttributes) {

    window.OpenProject.pluginContext.valuesPromise().then((context) => {
      this.opModalService = context.services.opModalService;
      this.dynamicContentModal = context.classes.modals.dynamicContent;

      // Find activation link
      var activationLink = $element.find('.modal-wrapper--activation-link');
      if (this.activationLinkId) {
        activationLink = jQuery(this.activationLinkId);
      }

      // Set modal class name
      if ($attrs['modalClassName']) {
        this.modalClassName = $attrs['modalClassName'];
      }

      // Set template from wrapped element
      const wrappedElement = $element.find('.modal-wrapper--content');
      this.modalBody = wrappedElement.html();

      if ($attrs['iframeUrl']) {
        this.appendIframe($attrs['iframeUrl']);
      }

      if (!!$attrs['initialize']) {
        this.initialize();
      }
      else {
        activationLink.click(() => this.initialize());
      }

    });
  }

  public initialize() {
    let modal = this.opModalService.show(this.dynamicContentModal, { modalBody: this.modalBody, modalClassName: this.modalClassName });
    modal.openingEvent.subscribe((modal:any) => {
      //HACK: need to trigger an angular digest in order to have the
      //modal template be evaluated. Without it, the onInit will not be run.
      jQuery('.op-modal--modal-container').click();
    });
  }

  private appendIframe(url:string) {
    let subdom = angular.element(this.modalBody);
    let iframe = angular.element('<iframe frameborder="0" height="400" allowfullscreen>></iframe>');
    iframe.attr('src', url);

    subdom.find(this.iframeSelector).append(iframe);

    this.modalBody = subdom.html();
  }
}

function modalWrapper():any {
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

openprojectLegacyModule.directive('modalWrapper', modalWrapper);
