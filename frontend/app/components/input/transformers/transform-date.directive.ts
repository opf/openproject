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

function transformDate(TimezoneService:any) {
  return {
    restrict:'A',
    require: '^ngModel',
    link: function(
      scope:ng.IScope,
      element:ng.IAugmentedJQuery,
      attrs:ng.IAttributes,
      ngModelController:any) {
      ngModelController.$parsers.push(function(data:any) {
        if (moment(data, 'YYYY-MM-DD', true).isValid()) {
          return data;
        } else {
          return null;
        }
      });
      ngModelController.$formatters.push(function(data:any) {
        if (moment(data, 'YYYY-MM-DD', true).isValid()) {
          var d = TimezoneService.parseDate(data);
          return TimezoneService.formattedISODate(d);
        } else {
          return null;
        }
      });
    }
  };
}

// TODO:deprecate and replace by transformDate
angular
  .module('openproject')
  .directive('transformDateValue', transformDate);

// angular
//   .module('openproject')
//   .directive('transformDate', transformDate);
