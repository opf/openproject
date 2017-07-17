//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
//++

var CostsByTypeDisplayField = require('./components/wp-display/field-types/wp-display-costs-by-type-field.module').CostsByTypeDisplayField;
var CurrencyDisplayField = require('./components/wp-display/field-types/wp-display-currency-field.module').CurrencyDisplayField;

// Register Budget as select inline edit
angular
  .module('openproject')
  .run(['wpEditField', function(wpEditField) {
    wpEditField.extendFieldType('select', ['Budget']);
  }]);

// Register the costs attributes for display
angular
  .module('openproject')
  .run(['wpDisplayField', function(wpDisplayField) {
    wpDisplayField.extendFieldType('resource', ['Budget']);
    wpDisplayField.addFieldType(CostsByTypeDisplayField, 'costs', ['costsByType']);
    wpDisplayField.addFieldType(CurrencyDisplayField, 'currency', ['laborCosts', 'materialCosts', 'overallCosts']);
  }]);

// main app
var openprojectCostsApp = angular.module('openproject');

openprojectCostsApp.run(['HookService', function(HookService) {
  HookService.register('workPackageAttributeEditableType', function(params) {
    switch (params.type) {
      case 'Budget':
        return 'drop-down';
    }
    return null;
  });

  HookService.register('workPackageDetailsMoreMenu', function(params) {
    return [{
      key: 'log_costs',
      resource: 'workPackage',
      link: 'logCosts',
      css: ["icon-projects"]
    }];
  });

  HookService.register('workPackageTableContextMenu', function(params) {
    return {
      link: 'logCosts',
      indexBy: function(actions) {
        var index = _.findIndex(actions, { link: 'logTime' });
        return index !== -1 ? index + 1 : actions.length;
      },
      text: I18n.t('js.button_log_costs'),
      icon: 'projects'
    };
  });
}]);

var requireComponent = require.context('./components/', true, /^((?!\.(test|spec)).)*\.(js|ts)$/);
requireComponent.keys().forEach(requireComponent);
