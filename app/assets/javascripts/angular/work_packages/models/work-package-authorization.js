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

angular.module('openproject.workPackages.models')

.factory('WorkPackageAuthorization', [function() {

  WorkPackageAuthorization = function (workPackage, permittedActions) {
    var workPackageActions = Object.keys(workPackage.links);
    var validActions = permittedActions.filter(function(action) {
      return workPackageActions.indexOf(action) >= 0;
    });

    this.permittedActions = {};

    angular.forEach(validActions, function(action) {
      this.links[action] = this.workPackage.links[action].href;
    }, { links: this.permittedActions, workPackage: workPackage });

    angular.extend(this, workPackage);
  };

  WorkPackageAuthorization.prototype = {
    can: function(verb) {
      return this.permittedActions.indexOf(verb) >= 0;
    },

    cannot: function(verb) {
      return !this.can(verb);
    },
  };

  return WorkPackageAuthorization;
}]);
