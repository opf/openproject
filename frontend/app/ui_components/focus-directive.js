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

// TODO move to UI components
module.exports = function(FocusHelper) {

  function isSelect2Element(attrs) {
    var select2attributes = Object.keys(attrs).filter(function(attribute) {
      return attribute.search(/select2/i) >= 0;
    });

    return select2attributes.length > 0;
  }

  function updateFocus(scope, element, attrs) {
    if (element.hasClass('ui-select-multiple')) {
      return element.find('input.ui-select-search').focus();
    }

    var condition = (attrs.focus) ? scope.$eval(attrs.focus) : true;

    if (condition) {
      if (isSelect2Element(attrs)) {
        FocusHelper.focusSelect2Element(element);
      } else {
        FocusHelper.focusElement(element);
      }
    }
  }

  return {
    link: function(scope, element, attrs) {
      updateFocus(scope, element, attrs);

      scope.$on('updateFocus', function() {
        updateFocus(scope, element, attrs);
      });
    }
  };
};
