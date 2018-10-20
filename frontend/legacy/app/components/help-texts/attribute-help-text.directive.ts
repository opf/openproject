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
import {openprojectLegacyModule} from "../../openproject-legacy-app";

export class AttributeHelpTextController {
  // Attribute to show help text for
  public attribute:string;
  // Scope to search for
  public attributeScope:string;
  // Load single id entry if given
  public helpTextId?:string;
  public additionalLabel?:string;

  public exists:boolean = false;
  public text:any;
  public i18n:any;
  protected helpTextDm:any;
  protected attributeHelpTextsService:any;
  protected attributeHelpTextsModal:any;
  protected opModal:any;

  constructor(protected $element:IAugmentedJQuery,
              protected $scope:angular.IScope) {

    window.OpenProject.getPluginContext().then((context) => {
      this.i18n = context.services.i18n;
      this.helpTextDm = context.services.helpTextDm;
      this.opModal = context.services.opModalService;
      this.attributeHelpTextsService = context.services.attributeHelpTexts;
      this.attributeHelpTextsModal = context.classes.modals.attributeHelpTexts;

      this.text = {
        open_dialog: this.i18n.t('js.help_texts.show_modal')
      };

      if (this.helpTextId) {
        this.exists = true;
      } else {
        // Need to load the promise to find out if the attribute exists
        this.load().then((resource:any) => {
          console.log(resource);
          this.exists = !!resource;
          return resource;
        });
      }

      // HACK: without this, the template is not displayed
      setTimeout(() => this.$scope.$apply());
    });
  }

  public $onInit() {
    // Created for interface compliance
  }

  public handleClick() {
    this.load().then((resource:any) => {
      let modal = this.opModal.show(this.attributeHelpTextsModal, { helpText: resource });
      modal.openingEvent.subscribe((modal:any) => {
        setTimeout(() => {
          //HACK: need to trigger an angular digest in order to have the
          //modal template be evaluated. Without it, the onInit will not be run.
          jQuery('.op-modal--modal-container').click();
        }, 0);
      });
    });
  }

  private load() {
    if (this.helpTextId) {
      return this.helpTextDm.load(this.helpTextId);
    } else {
      return this.attributeHelpTextsService.require(this.attribute, this.attributeScope);
    }
  }
}

openprojectLegacyModule.component('attributeHelpText', {
  template: require('!!raw-loader!./help-text.directive.html'),
  controller: AttributeHelpTextController,
  controllerAs: '$ctrl',
  bindings: {
    attribute: '@',
    attributeScope: '@',
    helpTextId: '@?',
    additionalLabel: '@?'
  }
});
