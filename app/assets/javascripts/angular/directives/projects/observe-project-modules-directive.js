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

angular.module('openproject.projects.directives')

.directive('observeProjectModules', [function() {
  return {
    restrict: 'EA',
    require: '^checkable',
    link: function(scope, element, attrs, checkableCtrl) {

      // Hides types and issues custom fields on the new project form when
      // work_package_tracking module is disabled.
      if (attrs.checkboxId == "project_enabled_module_names_work_package_tracking") { 
        var update = function(state) {
          if (state) {
            jQuery('#project_types, #project_issue_custom_fields').show();
          } else {
            jQuery('#project_types, #project_issue_custom_fields').hide();
          }
        };
        checkableCtrl.requestNotification(update);
      }
    }
  };
}]);
