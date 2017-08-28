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
import {openprojectModule} from '../../angular-modules';

export class WorkPackageResizerController {
  private detailsSide:HTMLElement;
  private elementFlex:number;
  private oldPosition:number;
  private mouseMoveHandler:any;

  constructor(public $element:ng.IAugmentedJQuery) {
    // Get element & starting width
    this.detailsSide = <HTMLElement>document.getElementsByClassName('work-packages-split-view--details-side')[0];
    this.elementFlex = localStorage.getItem("detailsSideFlexBasis") ? parseInt(localStorage.getItem("detailsSideFlexBasis")) : 582;

    // Apply width if stored in local storage
    this.detailsSide.style.flexBasis = this.elementFlex + 'px';

    // Add event listener
    this.$element[0].addEventListener('mousedown', this.handleMouseDown.bind(this));
    window.addEventListener('mouseup', this.handleMouseUp.bind(this));
  }

  private handleMouseDown(e:MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    // Gettig starting position
    this.oldPosition = e.clientX;

    // Necessary to encapsulate this to be able to remove the eventlistener later
    this.mouseMoveHandler = this.resizeElement.bind(this, this.detailsSide);

    // Enable mouse move
    window.addEventListener('mousemove', this.mouseMoveHandler);
  }

  private handleMouseUp(e:MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    // Disable mouse move
    window.removeEventListener('mousemove', this.mouseMoveHandler);
  }

  private resizeElement(element:HTMLElement, e:MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    // Get delta to resize
    let delta = this.oldPosition - e.clientX;
    this.oldPosition = e.clientX;

    // Get new value depending on the delta
    // The detailsSide is not allowed to be smaller than 480px and greater than 1300px
    this.elementFlex = this.elementFlex + delta;
    let newValue = this.elementFlex < 480 ? 480 : this.elementFlex;
    newValue = newValue > 1300 ? 1300 : newValue;

    // Store item in local storage
    localStorage.setItem("detailsSideFlexBasis", String(newValue));

    // Set new width
    element.style.flexBasis = newValue + 'px';
  }
}

function wpResizer() {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-resizer/wp-resizer.directive.html',
    scope: {},

    bindToController: true,
    controllerAs: '$ctrl',
    controller: WorkPackageResizerController
  };
}

openprojectModule.directive('wpResizer', wpResizer);
