import {Directive, ElementRef, Injector, Input} from '@angular/core';
import {UpgradeComponent} from '@angular/upgrade/static';
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
  private resizingElement:HTMLElement;
  private elementFlex:number;
  private oldPosition:number;
  private mouseMoveHandler:any;
  public resizeEvent:string;
  public elementClass: string;
  public localStorageKey: string;

  constructor(public $element:ng.IAugmentedJQuery) {
  }

  $onInit() {
    // Get element
    this.resizingElement = <HTMLElement>document.getElementsByClassName(this.elementClass)[0];

    // Get inital width from local storage and apply
    let localStorageValue = window.OpenProject.guardedLocalStorage(this.localStorageKey);
    this.elementFlex = localStorageValue ? parseInt(localStorageValue, 10) : this.resizingElement.offsetWidth;

    // This case only happens when the timeline is loaded but not displayed.
    // Therefor the flexbasis will be set to 50%, just in px
    if (this.elementFlex === 0 && this.resizingElement.parentElement ) {
      this.elementFlex = this.resizingElement.parentElement.offsetWidth / 2;
    }
    this.resizingElement.style.flexBasis = this.elementFlex + 'px';

    // Apply two column layout
    this.resizingElement.classList.toggle('-columns-2', this.elementFlex > 700);

    // Add event listener
    this.$element[0].addEventListener('mousedown', this.handleMouseDown.bind(this));
    window.addEventListener('mouseup', this.handleMouseUp.bind(this));
  }

  private handleMouseDown(e:MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    // Only on left mouse click the resizing is started
    if(e.buttons === 1 || e.which === 1) {
      // Gettig starting position
      this.oldPosition = e.clientX;

      // Necessary to encapsulate this to be able to remove the eventlistener later
      this.mouseMoveHandler = this.resizeElement.bind(this, this.resizingElement);

      // Change cursor icon
      // This is handled via JS to ensure
      // that the cursor stays the same even when the mouse leaves the actual resizer.
      document.getElementsByTagName("body")[0].setAttribute('style', 'cursor: col-resize !important');

      // Enable mouse move
      window.addEventListener('mousemove', this.mouseMoveHandler);
    }
  }

  private handleMouseUp(e:MouseEvent) {
    // Disable mouse move
    window.removeEventListener('mousemove', this.mouseMoveHandler);

    // Change cursor icon back
    document.getElementsByTagName("body")[0].style.cursor = 'auto';

    // Take care at the end that the elemntFlex-Value is the same as the acutal value
    // When the mouseup is outside the container these values will differ
    // which will cause problems at the next movement start
    let localStorageValue = window.OpenProject.guardedLocalStorage(this.localStorageKey);
    if (localStorageValue) {
      this.elementFlex = parseInt(localStorageValue, 10);
    }

    // Send a event that we resized this element
    const event = new Event(this.resizeEvent);
    window.dispatchEvent(event);
  }

  private resizeElement(element:HTMLElement, e:MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    // Get delta to resize
    let delta = this.oldPosition - e.clientX;
    this.oldPosition = e.clientX;

    // Get new value depending on the delta
    // The resizingElement is not allowed to be smaller than 480px
    this.elementFlex = this.elementFlex + delta;
    let newValue = this.elementFlex < 480 ? 480 : this.elementFlex;

    // Store item in local storage
    window.OpenProject.guardedLocalStorage(this.localStorageKey, String(newValue));

    // Apply two column layout
    element.classList.toggle('-columns-2', newValue > 700);

    // Set new width
    element.style.flexBasis = newValue + 'px';
  }
}

function wpResizer():any {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-resizer/wp-resizer.directive.html',
    scope: {
      elementClass: '<',
      resizeEvent: '@',
      localStorageKey: '<'
    },

    bindToController: true,
    controllerAs: '$ctrl',
    controller: WorkPackageResizerController
  };
}

openprojectModule.directive('wpResizer', wpResizer);


@Directive({
  selector: 'wp-resizer'
})
export class WpResizerDirectiveUpgraded extends UpgradeComponent {

  @Input() elementClass:string;

  @Input() resizeEvent:string;

  @Input() localStorageKey:string;

  constructor(elementRef:ElementRef, injector:Injector) {
    super('wpResizer', elementRef, injector);
  }
}
