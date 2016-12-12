//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General License version 3.
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

import {opUiComponentsModule} from '../../../angular-modules';

export class InteractiveTableController {
  static eventName = 'op:tableChanged';

  // Width of the table and container last applied by this directive
  private lastWidthSet;

  // Width of the scrollbar to account for
  private scrollBarWidth = 16;

  constructor(protected $element,
              protected $timeout,
              protected $interval,
              protected $scope,
              protected $window) {
    'ngInject';

    // Initialize the interactive table
    $timeout(() => {
      this.cloneSpacer();
      this.setTableWidths();
    });

    // Watch for global resize events
    // (e.g., table should expand to full width of window)
    angular.element($window).on('resize', _.debounce(() => this.setTableWidths(), 50));

    // Watch for changes in state
    // (e.g., detail view opening)
    $scope.$on('$stateChangeSuccess', () => {
      $timeout(() => this.setTableWidths(), 200);
    });

    // Watch for changes in the project navigation menu
    $scope.$on('openproject.layout.navigationToggled', () => {
      $timeout(() => this.setTableWidths(), 200);
    });

    // Watch for updates not coming through the above methods
    // e.g., attributes in the table inititally rendering such as the progress bar
    // will cause the table width to expand
    var stopInterval = $interval(() => this.refreshWhenNeeded(), 1000, 0, false);
    $scope.$on('$destroy', () => {
      $interval.cancel(stopInterval);
    });

  }


  private get table() {
    return this.$element;
  }

  private get visible() {
    return this.table.is(':visible');
  }

  private getInnerContainer() {
    return this.table.parent('.generic-table--results-container');
  }

  private getOuterContainer() {
    return this.table.closest('.generic-table--container');
  }

  private getBackgrounds() {
    return this.getInnerContainer()
               .find('.generic-table--header-background,.generic-table--footer-background');
  }

  private getHeadersFooters() {
    return this.table.find(
      '.generic-table--sort-header-outer,' +
      '.generic-table--header-outer,' +
      '.generic-table--footer-outer'
    );
  }

  private cloneSpacer() {
    this.getHeadersFooters().each((i, el) => {
      var element = angular.element(el);
      var html = element.text();
      var hiddenForSighted = element.find('.hidden-for-sighted').text();

      html = html.replace(hiddenForSighted, '');

      var spacerHtml = '<div class="generic-table--column-spacer">' + html + '</div>';

      var newElement = angular.element(spacerHtml);

      newElement.appendTo(element.parent());
    });
  };


  /**
   * Return the actual width of the table element (including scrollbar if necessary)
   */
  private currentWidth() {
    return this.table.width();
  }

  /**
   * Re-adjust the table's container widths
   */
  private setTableContainerWidths() {
    var width = this.currentWidth();

    // account for a possible scrollbar
    if (width > document.documentElement.clientWidth - this.scrollBarWidth) {
      width += this.scrollBarWidth;
    }

    this.lastWidthSet = width;
    if (width > this.getOuterContainer().width()) {
      // force containers to the width of the table
      this.getInnerContainer().width(width);
      this.getBackgrounds().width(width);
    } else {
      // ensure table stretches to container sizes
      this.getInnerContainer().css('width', '100%');
      this.getBackgrounds().css('width', '100%');
    }
  }

  /**
   * Correct header and footer widths after table is updated.
   */
  private setHeaderFooterWidths() {
    this.getHeadersFooters().each((i, el) => {
      var element = angular.element(el);
      var spacer = element.parent();
      var width = spacer.width();

      if (width !== 0) {
        element.css('width', width + 'px')
               .parent().css('width', width + 'px');
      }
    });
  }

  /**
   * Reset all table element widths to auto.
   */
  private invalidateWidths() {
    this.getInnerContainer().css('width', 'auto');
    this.getBackgrounds().css('width', 'auto');
    this.getHeadersFooters().each((i, el) => {
      angular.element(el).css('width', 'auto');
    });
  }

  /**
   * Update the table itself and its containers after an external event.
   * (Resize, column content changes)
   */
  private setTableWidths() {
    this.invalidateWidths();
    this.setTableContainerWidths();
    this.setHeaderFooterWidths();

    this.table.trigger(InteractiveTableController.eventName);
  };

  private refreshWhenNeeded() {
    if (!this.visible) {
      return;
    }

    // If the inner width of the table changed due to some outer event,
    // adjust accordingly.
    var actualWidth = this.currentWidth();
    if (Math.abs(this.lastWidthSet - actualWidth) >= 10) {
      return this.setTableWidths();
    }

    // If any of the outer header widths changed,
    // adjust the fixed headers.
    this.getHeadersFooters().each((i, el) => {
      var element = angular.element(el);
      var width = element.parent().width();

      if (width !== 0 && element.outerWidth() !== width) {
        return this.setTableWidths();
      }
    });
  }

}

function interactiveTable() {
  return {
    restrict: 'A',
    controller: InteractiveTableController,
    bindToController: true,

    link: function(scope, element) {
      if (element.filter('table').length === 0) {
        throw 'interactive-table needs to be defined on a \'table\' tag';
      }
    }
  };
};

opUiComponentsModule.directive('interactiveTable', interactiveTable);
