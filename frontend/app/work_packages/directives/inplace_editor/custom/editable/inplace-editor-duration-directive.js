//-- copyright
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
//++

module.exports = function() {
  return {
    restrict: 'E',
    transclude: true,
    replace: true,
    scope: {},
    require: '^workPackageField',
    templateUrl: '/templates/work_packages/inplace_editor/custom/editable/duration.html',
    controllerAs: 'customEditorController',
    controller: function() {},
    link: function(scope, element, attrs, fieldController) {
      scope.fieldController = fieldController;
      if (fieldController.writeValue === null) {
        scope.customEditorController.writeValue = null;
      } else {
        scope.customEditorController.writeValue = Number(
          moment
            .duration(fieldController.writeValue)
            .asHours()
            .toFixed(2)
        );
      }
      scope.$watch('customEditorController.writeValue', function(value) {
        if (value === null) {
          fieldController.writeValue = null;
        } else {
          // get rounded minutes so that we don't have to send 12.223000000003
          // to the server
          var minutes = Number(moment.duration(value, 'hours').asMinutes().toFixed(2));
          fieldController.writeValue = moment.duration(minutes, 'minutes');
        }
      });
    }
  };
};
