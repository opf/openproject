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

import {openprojectLegacyModule} from "core-app/openproject-legacy-app";

require('angular');
import IAugmentedJQuery = angular.IAugmentedJQuery;

export class ConfirmFormSubmitController {

  // Allow original form submission after dialog was closed
  private confirmed = false;
  private text:any;

  private confirmDialog:any;
  private I18n:any;

  constructor(protected $element:IAugmentedJQuery) {
    window.OpenProject.getPluginContext().then((context) => {
      this.confirmDialog = context.services.confirmDialog;
      this.I18n = context.services.i18n;

      this.text = {
        title: this.I18n.t('js.modals.form_submit.title'),
        text: this.I18n.t('js.modals.form_submit.text')
      };
    });

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
    this.confirmDialog.confirm({
      text: this.text,
      closeByEscape: true,
      showClose: true,
      closeByDocument: true,
    }).then(() => {
        this.confirmed = true;
        this.$element.trigger('submit');
      })
      .catch(() => this.confirmed = false);
    }
  }

  function confirmFormSubmit():any {
    return {
      restrict: 'AC',
      scope: {},
      bindToController: true,
      controller: ConfirmFormSubmitController,
      controllerAs: '$ctrl',
    };
}

openprojectLegacyModule
  .directive('confirmFormSubmit', confirmFormSubmit);
