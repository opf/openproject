//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {Component, ElementRef, HostListener, Input, OnInit} from '@angular/core';
import {distinctUntilChanged} from 'rxjs/operators';
import {TransitionService} from '@uirouter/core';
import {MainMenuToggleService} from "core-components/main-menu/main-menu-toggle.service";
import {BrowserDetector} from "core-app/modules/common/browser/browser-detector.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  selector: 'wp-resizer',
  template: `
    <div class="work-packages--resizer icon-resizer-vertical-lines"></div>`
})

export class WpResizerDirective extends UntilDestroyedMixin implements OnInit {
  @Input() elementClass:string;
  @Input() resizeEvent:string;
  @Input() localStorageKey:string;
  @Input() resizeStyle:'flexBasis'|'width' = 'flexBasis';

  private resizingElement:HTMLElement;
  private elementWidth:number;
  private oldPosition:number;
  private mouseMoveHandler:any;
  private element:HTMLElement;

  public moving:boolean = false;

  constructor(readonly toggleService:MainMenuToggleService,
              private elementRef:ElementRef,
              readonly $transitions:TransitionService,
              readonly browserDetector:BrowserDetector) {
    super();
  }

  ngOnInit() {
    // Get element
    this.resizingElement = <HTMLElement>document.getElementsByClassName(this.elementClass)[0];

    // Get initial width from local storage and apply
    let localStorageValue = this.parseLocalStorageValue();
    this.elementWidth = localStorageValue || this.resizingElement.offsetWidth;

    // This case only happens when the timeline is loaded but not displayed.
    // Therefor the flexbasis will be set to 50%, just in px
    if (this.elementWidth === 0 && this.resizingElement.parentElement) {
      this.elementWidth = this.resizingElement.parentElement.offsetWidth / 2;
    }
    this.resizingElement.style[this.resizeStyle] = this.elementWidth + 'px';

    // Wait until dom content is loaded and initialize column layout
    // Otherwise function will be executed with empty list
    jQuery(document).ready(() => {
      this.applyColumnLayout(this.resizingElement, this.elementWidth);
    });

    // Add event listener
    this.element = this.elementRef.nativeElement;

    // Listen on sidebar changes and toggle column layout, if necessary
    this.toggleService.changeData$
      .pipe(
        distinctUntilChanged(),
        this.untilDestroyed()
      )
      .subscribe(changeData => {
        this.toggleFullscreenColumns();
      });
    let that = this;
    jQuery(window).resize(function () {
      that.toggleFullscreenColumns();
    });
  }

  ngOnDestroy() {
    super.ngOnDestroy();
    // Reset the style when killing this directive, otherwise the style remains
    this.resizingElement.style[this.resizeStyle] = '';
  }

  @HostListener('mousedown', ['$event'])
  private handleMouseDown(e:MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    // Only on left mouse click the resizing is started
    if (e.buttons === 1 || e.which === 1) {
      // Gettig starting position
      this.oldPosition = e.clientX;

      this.moving = true;

      // In case we dragged the resizer farther than the element can actually grow,
      // we reset it to the actual width at the start of the new resizing
      let localStorageValue = this.parseLocalStorageValue();
      let actualElementWidth = this.resizingElement.offsetWidth;
      if (localStorageValue && localStorageValue > actualElementWidth) {
        this.elementWidth = actualElementWidth;
      }

      // Necessary to encapsulate this to be able to remove the eventlistener later
      this.mouseMoveHandler = this.resizeElement.bind(this, this.resizingElement);

      // Change cursor icon
      // This is handled via JS to ensure
      // that the cursor stays the same even when the mouse leaves the actual resizer.
      document.getElementsByTagName("body")[0].setAttribute('style',
        'cursor: col-resize !important');

      // Enable mouse move
      window.addEventListener('mousemove', this.mouseMoveHandler);
      window.addEventListener('touchmove', this.mouseMoveHandler, { passive: false });
    }
  }

  @HostListener('window:touchend', ['$event'])
  private handleTouchEnd(e:MouseEvent) {
    window.removeEventListener('touchmove', this.mouseMoveHandler);
    let localStorageValue = this.parseLocalStorageValue();
    if (localStorageValue) {
      this.elementWidth = localStorageValue;
    }
  }

  @HostListener('window:mouseup', ['$event'])
  private handleMouseUp(e:MouseEvent):boolean {
    if (!this.moving) {
      return true;
    }

    // Disable mouse move
    window.removeEventListener('mousemove', this.mouseMoveHandler);

    // Change cursor icon back
    document.body.style.cursor = 'auto';

    // Take care at the end that the elementWidth-Value is the same as the actual value
    // When the mouseup is outside the container these values will differ
    // which will cause problems at the next movement start
    let localStorageValue = this.parseLocalStorageValue();
    if (localStorageValue) {
      this.elementWidth = localStorageValue;
    }

    this.moving = false;

    // Send a event that we resized this element
    const event = new Event(this.resizeEvent);
    window.dispatchEvent(event);

    return false;
  }

  private parseLocalStorageValue():number|undefined {
    let localStorageValue = window.OpenProject.guardedLocalStorage(this.localStorageKey);
    let number = parseInt(localStorageValue || '', 10);

    if (typeof number === 'number' && number !== NaN) {
      return number;
    }

    return undefined;
  }

  private resizeElement(element:HTMLElement, e:MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    // Get delta to resize
    let delta = this.oldPosition - (e.clientX || e.pageX);
    this.oldPosition = (e.clientX || e.pageX);

    // Get new value depending on the delta
    // The resizingElement is not allowed to be smaller than 530px
    this.elementWidth = this.elementWidth + delta;
    let newValue = this.elementWidth < 530 ? 530 : this.elementWidth;

    // Store item in local storage
    window.OpenProject.guardedLocalStorage(this.localStorageKey, String(newValue));

    // Apply two column layout
    this.applyColumnLayout(element, newValue);

    // Set new width
    element.style[this.resizeStyle] = newValue + 'px';
  }

  private applyColumnLayout(element:HTMLElement, newWidth:number) {
    // Apply two column layout in fullscreen view of a workpackage
    if (element === jQuery('.work-packages-full-view--split-right')[0]) {
      this.toggleFullscreenColumns();
    }
    // Apply two column layout when details view of wp is open
    else {
      this.toggleColumns(element, 700);
    }
  }

  private toggleColumns(element:HTMLElement, checkWidth:number = 750) {
    // Disable two column layout for MS Edge (#29941)
    if (element && !this.browserDetector.isEdge) {
      jQuery(element).toggleClass('-can-have-columns', element.offsetWidth > checkWidth);
    }
  }

  private toggleFullscreenColumns() {
    let fullScreenLeftView = jQuery('.work-packages-full-view--split-left')[0];
    this.toggleColumns(fullScreenLeftView);
  }
}
