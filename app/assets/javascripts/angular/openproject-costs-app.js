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

// main app
var openprojectCostsApp = angular.module('openproject');

openprojectCostsApp.run(['HookService',
                         'ConfigurationService',
                         'WorkPackagesOverviewService',
                         function(HookService, ConfigurationService, WorkPackagesOverviewService) {
  var addAttributesToGroup = function(group, attributes) {
    angular.forEach(attributes, function(id, attribute) {
      WorkPackagesOverviewService.addAttributeToGroup(group, id || attribute);
    });
  };

  var setupCostsAttributes = function() {
    var position = WorkPackagesOverviewService.getGroupedWorkPackageOverviewAttributes().length - 1;
    var costsAttributes = {
      costObject: null,
      overallCosts: null,
      summarizedCostEntries: 'spentUnits',
    };

    WorkPackagesOverviewService.addGroup('costs', position);

    addAttributesToGroup('costs', costsAttributes);
  };

  if (ConfigurationService.isModuleEnabled('costs_module')) {
    setupCostsAttributes();
  }

  HookService.register('workPackageOverviewAttributes', function(params) {
    var directive;

    switch (params.type) {
      case "spentUnits":
        var summarizedCostEntries = params.workPackage.embedded.summarizedCostEntries;

        if (summarizedCostEntries && summarizedCostEntries.length > 0) {
          directive = "summarized-cost-entries";
        }
        break;
      case "costObject":
        if (params.workPackage.embedded.costObject) {
          directive = "cost-object";
        }
        break;
    }

    return directive;
  });

  HookService.register('workPackageDetailsMoreMenu', function(params) {
    return { "log_costs": ["icon-unit"] };
  });
}]);
