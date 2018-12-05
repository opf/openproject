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

import {PluginContextService} from "core-app/services/plugin-context.service";

/*eslint no-eval: "error"*/
export class CostBudgetSubformController {

  // Container for rows
  private container: ng.IAugmentedJQuery;

  // Template for new rows to insert, is rendered with INDEX placeholder
  private rowTemplate: string;

  // Current row index
  public rowIndex: number;

  // subform item count as output by rails
  public itemCount: string;

  // Updater URL for the rows contained here
  public updateUrl: string;

  constructor(public $element:ng.IAugmentedJQuery,
              public $http:ng.IHttpService,
              public pluginContext:PluginContextService,
              private $scope:ng.IScope,
              private $compile:any) {

    this.container = $element.find('.budget-item-container');
    this.rowIndex = parseInt(this.$element.attr('item-count') as string);

      // Refresh row on changes
    $element.on('change', '.budget-item-value', (evt) => {
      var row = angular.element(evt.target).closest('.cost_entry');
      this.refreshRow(row.attr('id') as string);
    });

    $element.on('click', '.delete-budget-item', (evt) => {
      evt.preventDefault();
      var row = angular.element(evt.target).closest('.cost_entry');
      row.remove();
      return false;
    });

    // Add new row handler
    $element.find('.budget-add-row').click((evt) => {
      evt.preventDefault();
      this.addBudgetItem();
      return false;
    });
  }

  /**
   * Refreshes the given row after updating values
   */
  public refreshRow(row_identifier:string) {
    var row = this.$element.find('#' + row_identifier);
    var request = this.buildRefreshRequest(row, row_identifier);

    this.$http({
      url: this.updateUrl,
      method: 'POST',
      data: request,
      headers: { 'Accept': 'application/json' }
    }).then((response:any) => {
      _.each(response.data, (val:string, selector:string) => {
        jQuery('#' + selector).html(val);
      });
    }).catch(response => {
      this.pluginContext.context!.services.wpNotifications.handleErrorResponse(response);
    });
  }

  /**
   * Adds a new empty budget item row with the correct index set
   */
  public addBudgetItem() {
    let compiledTemplate = this.$compile(this.indexedTemplate)(this.$scope);
    this.container.append(compiledTemplate);
    this.rowIndex += 1;
  }

  /**
   * Return the next possible new row from rowTemplate,wpNotifications
   * with the index set to the current last value.
   */
  private get indexedTemplate() {
    return this.rowTemplate.replace(/INDEX/g, this.rowIndex.toString());
  }

  /**
   * Returns the params for the update request
   */
  private buildRefreshRequest(row:JQuery, row_identifier:string) {
    var request:any = {
      element_id: row_identifier,
      fixed_date: angular.element('#cost_object_fixed_date').val()
    };

    // Augment common values with specific values for this type
    row.find('.budget-item-value').each((_i:number, el:any) => {
      var field = angular.element(el);
      request[field.data('requestKey')] = field.val() || '0';
    });

    return request;
  }
}

function costsBudgetSubform():any {
  return {
    restrict: 'E',
    scope: {
      updateUrl: '@',
      itemCount: '@'
    },
    link: (scope:ng.IScope,
           element:ng.IAugmentedJQuery,
           attr:ng.IAttributes,
           ctrl:any) => {
      const template = element.find('.budget-row-template');
      ctrl.rowTemplate = template[0].outerHTML;
      template.remove();
    },
    bindToController: true,
    controller: CostBudgetSubformController,
    controllerAs: '$ctrl'
  };
}

angular.module('OpenProjectLegacy').directive('costsBudgetSubform', costsBudgetSubform);
