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
angular
  .module('openproject.workPackages.directives')
  .directive('wpVirtualScroll', wpVirtualScroll);

function getBlockNodes(nodes) {
  var node = nodes[0];
  var endNode = nodes[nodes.length - 1];
  var blockNodes = [node];

  do {
    node = node.nextSibling;
    if (!node) break;
    blockNodes.push(node);
  } while (node !== endNode);

  return $(blockNodes);
}

function wpVirtualScroll($window, $animate) {
  return {

    multiElement: true,
    transclude: 'element',
    // priority: 600,
    terminal: true,
    restrict: 'A',
    // $$tlb: true,

    link: ($scope, $element: IRootElementService, $attr, ctrl, $transclude) => {

      const parent = $element.parent();

      let block: any;
      let childScope: IScope;
      let previousElements: any;

      let tr = document.createElement("tr");
      let td = document.createElement("td");
      td.innerHTML = "&nbsp;";
      tr.appendChild(td);

      const value = true;

      if (value) {
        if (!childScope) {
          $transclude(function (clone, newScope) {
            childScope = newScope;
            block = {
              clone: clone
            };
              $animate.enter(clone, parent, $element);
          });
        }
      } else {
        if (previousElements) {
          previousElements.remove();
          previousElements = null;
        }
        if (childScope) {
          childScope.$destroy();
          childScope = null;
        }
        if (block) {
          previousElements = getBlockNodes(block.clone);
          $animate.leave(previousElements).then(function () {
            previousElements = null;
          });
          block = null;
        }

        // adding dummy row
        parent.append(tr);
      }

    }
  };
}
