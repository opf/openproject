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

module.exports = function($timeout, $window){
  return {
    restrict: 'A',

    link: function(scope, element) {
      if (getTable().filter('table').length === 0) {
        throw 'interactive-table needs to be defined on a \'table\' tag';
      }

      function getTable() {
        return element;
      }

      function getInnerContainer() {
        return element.parent('.generic-table--results-container');
      }

      function getOuterContainer() {
        return element.closest('.generic-table--container');
      }

      function isWorkPackagesTable () {
        return element.closest('.work-package-table--container').length !== 0;
      }

      function getBackgrounds() {
        return getInnerContainer().find('.generic-table--header-background,' +
                                        '.generic-table--footer-background');
      }

      function getHeadersFooters() {
        return element.find(
          '.generic-table--sort-header-outer,' +
          '.generic-table--header-outer,' +
          '.generic-table--footer-outer'
        );
      }

      function setTableContainerWidths() {
        // adjust overall containers
        var tableWidth = getTable().width(),
          scrollBarWidth = 16;

        // account for a possible scrollbar
        if (tableWidth > document.documentElement.clientWidth - scrollBarWidth) {
          tableWidth += scrollBarWidth;
        }
        if (tableWidth > getOuterContainer().width()) {
          // force containers to the width of the table
          getInnerContainer().width(tableWidth);
          getBackgrounds().width(tableWidth);
        } else {
          // ensure table stretches to container sizes
          getInnerContainer().css('width', '100%');
          if(isWorkPackagesTable()) {
            // HACK: This prevents a horizontal scroll bar in
            //       the work package table when there is nothing to scroll
            getBackgrounds().css('width', 'calc(100% - 10px)');
          }
          else {
            getBackgrounds().css('width', '100%');
          }
        }
      }

      function setHeaderFooterWidths() {
        getHeadersFooters().each(function() {
          var spacer = angular.element(this).parent();

          var width = spacer.width();

          if (width !== 0) {
            angular.element(this).css('width', width + 'px');
          }
        });
      }

      function invalidateWidths() {
        getInnerContainer().css('width', 'auto');
        getBackgrounds().css('width', 'auto');
        getHeadersFooters().each(function() {
          angular.element(this).css('width', 'auto');
        });
      }

      var setTableWidths = function() {
        if(!getTable().is(':visible')) {
          return;
        }
        $timeout(function() {
          invalidateWidths();
          setTableContainerWidths();
          setHeaderFooterWidths();
        });
      };

      var cloneSpacer = function() {
        getHeadersFooters().each(function() {
          var html = angular.element(this).text();
          var hiddenForSighted = angular.element(this).find('.hidden-for-sighted').text();

          html = html.replace(hiddenForSighted, '');

          var spacerHtml = '<div class="generic-table--column-spacer">' + html + '</div>';

          var newElement = angular.element(spacerHtml);

          newElement.appendTo(angular.element(this).parent());
        });
      };

      var initialize = function() {
        cloneSpacer();
        setTableWidths();
      };

      var mouseoverHandler = function () {
        angular.element(this).off('mouseover', mouseoverHandler);
        setHeaderFooterWidths();
      };

      angular.element(element)
        .closest('.generic-table--container')
        .on('mouseover', mouseoverHandler);

      $timeout(initialize);
      angular.element($window).on('resize', _.debounce(setTableWidths, 50));
      scope.$on('$stateChangeSuccess', function() {
        $timeout(setTableWidths, 200);
      });
      scope.$on('openproject.layout.navigationToggled', function() {
        $timeout(setTableWidths, 200);
      });
    }
  };
};
