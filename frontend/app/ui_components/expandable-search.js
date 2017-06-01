//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

module.exports = function(ENTER_KEY) {
  return {
    restrict: 'E',
    replace: true,
    link: function(scope, elem) {
      var btn = elem.find('a'),
        input = elem.find('input'),
        setCollapsed;

      // Search is collapsed initially
      scope.collapsed = true;
      setCollapsed = function(collapsedState) {
          scope.collapsed = collapsedState;
          scope.$apply();
        };

      btn.on('click mousedown focus keypress', function(evt) {
        if (scope.collapsed === true) {
          setCollapsed(false);
          // Force focus to the search input
          // The somewhat arbitrary delay of 20ms is required
          // since Firefox blocks focus changing events
          // immdetiately after an element is focused.
          // Smaller delays will cause Firefox to ignore that focus
          // Relevant: http://stackoverflow.com/questions/7046798
          setTimeout(function() { input.focus(); }, 20);

          // Hide on lost focus
          elem.on('focusout', function() {
            // Allow DOM to propagate new focus
            setTimeout(function() {
              // Hide unless icon clicked
              if (elem.find(':active,:focus').length === 0) {
                setCollapsed(true);
                elem.off('focusout');
              }
            }, 10);
          });
          evt.preventDefault();
        } else {
          // Submit only when clicked or enter on btn
          if (evt.type === 'mousedown' ||
             (evt.type === 'keypress' && evt.which === ENTER_KEY)) {
            elem.closest('form').submit();
          }
        }
      });
    }
  };
};
