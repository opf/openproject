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

module.exports = function(VersionService) {
  function getDropdownSortingStrategy(field) {
    var sorting;

    switch(field) {
      case 'version':
        sorting = function(option) {
          var definingProject = VersionService.getDefininingProject(option) || '';

          // This is a hack to work around limited lodash multi-attribute
          // sorting and works fine for string-based sorting in our case.
          // TODO Possibly refactor when v3 hits
          return definingProject + '_' + option.name.toLowerCase();
        };
        break;
      default:
        sorting = null;
    }
    return sorting;
  }

  function getDropDownOptionGroup(field, option) {
    switch(field) {
      case 'version':
        return VersionService.getDefininingProject(option);
        break;
    }
  }

  return {
    getDropdownSortingStrategy: getDropdownSortingStrategy,
    getDropDownOptionGroup: getDropDownOptionGroup
  };
};
