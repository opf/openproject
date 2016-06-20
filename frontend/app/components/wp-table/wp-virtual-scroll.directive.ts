// -- copyright
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
// ++

import IScope = angular.IScope;
import IRootElementService = angular.IRootElementService;
import IAnimateProvider = angular.IAnimateProvider;
import ITranscludeFunction = angular.ITranscludeFunction;

angular
  .module('openproject.workPackages.directives')
  .directive('wpVirtualScrollRow', wpVirtualScrollRow);

let counter = 0;

function getBlockNodes(nodes) {
  var node = nodes[0];
  var endNode = nodes[nodes.length - 1];
  var blockNodes = [node];

  do {
    node = node.nextSibling;
    if (!node) {
      break;
    }
    blockNodes.push(node);
  } while (node !== endNode);

  return $(blockNodes);
}

function createDummyRow(content: any) {
  const tr = document.createElement('tr');
  const td = document.createElement('td');
  td.innerHTML = content;
  tr.appendChild(td);
  return tr;
}

function wpVirtualScrollRow($animate: any) {
  return {

    multiElement: true,
    transclude: 'element',
    priority: 600,
    terminal: true,
    restrict: 'A',
    $$tlb: true,

    link: ($scope: IScope,
           $element: IRootElementService,
           $attr: any,
           ctrl: any,
           $transclude: ITranscludeFunction) => {

      new RowDisplay($animate, $scope, $element, $attr, $transclude);
    }
  };
}

class RowDisplay {

  private visible = false;
  private block: any;
  private childScope: IScope;
  private previousElements: any;

  constructor(private $animate: any,
              private $scope: angular.IScope,
              private $element: angular.IRootElementService,
              private $attr: any,
              private $transclude: angular.ITranscludeFunction) {

    // setInterval(() => {
    //   if (this.visible) {
    //     this.hide();
    //   } else {
    //     this.show();
    //   }
    // }, 5 * 1000);

    // if (this.isVisible()) {
    this.show(counter++);
  }

  private isVisible() {
    return true;
  }

  private show(index: number) {
    this.visible = true;

    if (!this.childScope) {
      if (index % 2 === 0) {
        this.$transclude((clone: any, newScope: any) => {
          this.childScope = newScope;
          clone[clone.length++] = document.createComment(' wp-virtual-scroll: ' + index + ' ');
          this.block = {
            clone: clone
          };
          this.$animate.enter(clone, this.$element.parent(), this.$element);
        });
      } else {
        let row = createDummyRow(index);
        this.$animate.enter(row, this.$element.parent(), this.$element);
      }
    }

    setTimeout(() => this.$scope.$apply(), 0);
  }

  private hide() {
    this.visible = false;

    if (this.previousElements) {
      this.previousElements.remove();
      this.previousElements = null;
    }
    if (this.childScope) {
      this.childScope.$destroy();
      this.childScope = null;
    }
    if (this.block) {
      this.previousElements = getBlockNodes(this.block.clone);
      this.$animate.leave(this.previousElements).then(() => {
        this.previousElements = null;
      });
      this.block = null;
    }

    setTimeout(() => this.$scope.$apply(), 0);
  }


}
