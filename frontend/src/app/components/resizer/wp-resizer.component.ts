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

import {ChangeDetectorRef, Component, ElementRef, HostListener, Injector, Input, OnDestroy, OnInit} from '@angular/core';
import {distinctUntilChanged} from 'rxjs/operators';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {MainMenuToggleService} from "core-components/resizer/main-menu-toggle.service";

@Component({
  selector: 'wp-resizer',
  template: `<div class="work-packages--resizer icon-resizer-vertical-lines"></div>`
})

export class WpResizerDirective implements OnInit, OnDestroy {
  @Input() elementClass:string;
  @Input() resizeEvent:string;
  @Input() localStorageKey:string;

  private resizingElement:HTMLElement;
  private elementFlex:number;
  private oldPosition:number;
  private mouseMoveHandler:any;
  private element:HTMLElement;

  public moving:boolean = false;

  constructor(readonly toggleService:MainMenuToggleService,
              private elementRef:ElementRef) {
  }

  ngOnInit() {
    // Get element
    this.resizingElement = <HTMLElement>document.getElementsByClassName(this.elementClass)[0];

    // Get initial width from local storage and apply
    let localStorageValue = window.OpenProject.guardedLocalStorage(this.localStorageKey);
    this.elementFlex = localStorageValue ? parseInt(localStorageValue,
      10) : this.resizingElement.offsetWidth;

    // This case only happens when the timeline is loaded but not displayed.
    // Therefor the flexbasis will be set to 50%, just in px
    if (this.elementFlex === 0 && this.resizingElement.parentElement) {
      this.elementFlex = this.resizingElement.parentElement.offsetWidth / 2;
    }
    this.resizingElement.style.flexBasis = this.elementFlex + 'px';

    // Wait until dom content is loaded and initialize column layout
    // Otherwise function will be executed with empty list
    jQuery(document).ready(() => {
      this.applyColumnLayout(this.resizingElement, this.elementFlex);
      this.applyInfoRowLayout();
    });

    // Add event listener
    this.element = this.elementRef.nativeElement;

    // Listen on sidebar changes and toggle column layout, if necessary
    this.toggleService.changeData$
      .pipe(
        distinctUntilChanged(),
        untilComponentDestroyed(this)
      )
      .subscribe( changeData => {
        jQuery('.-can-have-columns').toggleClass('-columns-2', jQuery('.work-packages-full-view--split-left').width() > 750);
      });
    let that = this;
    jQuery(window).resize(function() {
      jQuery('.-can-have-columns').toggleClass('-columns-2', jQuery('.work-packages-full-view--split-left').width() > 750);
      that.applyInfoRowLayout();
    });
  }

  ngOnDestroy() {
    // Reset the style when killing this directive, otherwise the style remains
    this.resizingElement.style.flexBasis = null;
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

      // Necessary to encapsulate this to be able to remove the eventlistener later
      this.mouseMoveHandler = this.resizeElement.bind(this, this.resizingElement);

      // Change cursor icon
      // This is handled via JS to ensure
      // that the cursor stays the same even when the mouse leaves the actual resizer.
      document.getElementsByTagName("body")[0].setAttribute('style',
        'cursor: col-resize !important');

      // Enable mouse move
      window.addEventListener('mousemove', this.mouseMoveHandler);
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

    // Take care at the end that the elemntFlex-Value is the same as the acutal value
    // When the mouseup is outside the container these values will differ
    // which will cause problems at the next movement start
    let localStorageValue = window.OpenProject.guardedLocalStorage(this.localStorageKey);
    if (localStorageValue) {
      this.elementFlex = parseInt(localStorageValue, 10);
    }

    this.moving = false;

    // Send a event that we resized this element
    const event = new Event(this.resizeEvent);
    window.dispatchEvent(event);

    return false;
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
    this.applyColumnLayout(element, newValue);

    // Apply info row Layout
    this.applyInfoRowLayout();

    // Set new width
    element.style.flexBasis = newValue + 'px';
  }

  private applyColumnLayout(element:HTMLElement, newWidth:number) {
    // Apply two column layout in fullscreen view of a workpackage
    if (element === jQuery('.work-packages-full-view--split-right')[0]) {
      jQuery('.-can-have-columns').toggleClass('-columns-2', jQuery('.work-packages-full-view--split-left').width() > 750);
    }
    // Apply two column layout when details view of wp is open
    else {
      element.classList.toggle('-columns-2', newWidth > 700);
    }
  }

  private applyInfoRowLayout() {
    jQuery('.wp-info-wrapper').toggleClass('-wrapped', jQuery('.wp-info-wrapper').width() - jQuery('wp-custom-actions').width() - jQuery('wp-status-button .button').width() < 475);
  }
}
