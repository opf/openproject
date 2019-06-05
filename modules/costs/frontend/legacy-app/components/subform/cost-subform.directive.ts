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

export class CostSubformController {

  // Container for rows
  private container: ng.IAugmentedJQuery;

  // Template for new rows to insert, is rendered with INDEX placeholder
  private rowTemplate: string;

  // Current row index
  public rowIndex: number;

  // subform item count as output by rails
  public itemCount: string;

  constructor(public $element:ng.IAugmentedJQuery) {
    this.container = $element.find('.subform-container');
    this.rowIndex = parseInt(this.$element.attr('item-count') as string);

    $element.on('click', '.delete-row-button,.delete-budget-item', (evt:JQueryEventObject) => {
      var row = angular.element(evt.target).closest('.subform-row');
      row.remove();
      return false;
    });

    // Add new row handler
    $element.find('.add-row-button,.wp-inline-create--add-link').click((evt) => {
      evt.preventDefault();
      this.addRow();
      return false;
    });
  }

  /**
   * Adds a new empty budget item row with the correct index set
   */
  public addRow() {
    this.container.append(this.indexedTemplate);
    this.rowIndex += 1;

    this.container.find('.costs-date-picker').datepicker();
    this.container.find('.subform-row:last-child input:first').focus();
  }

  /**
   * Return the next possible new row from rowTemplate,
   * with the index set to the current last value.
   */
  private get indexedTemplate() {
    return this.rowTemplate.replace(/INDEX/g, this.rowIndex.toString());
  }
}

function costsSubform():any {
  return {
    restrict: 'E',
    scope: { itemCount: '@' },
    link: (scope:ng.IScope,
           element:ng.IAugmentedJQuery,
           attr:ng.IAttributes,
           ctrl:any) => {
      const template = element.find('.subform-row-template');
      ctrl.rowTemplate = template[0].outerHTML;
      template.remove();
    },
    bindToController: true,
    controller: CostSubformController,
    controllerAs: '$ctrl'
  };
}

angular.module('OpenProjectLegacy').directive('costsSubform', costsSubform);
