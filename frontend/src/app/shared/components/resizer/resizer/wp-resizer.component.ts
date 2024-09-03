//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { AfterViewInit, ChangeDetectionStrategy, Component, ElementRef, Input, OnInit } from '@angular/core';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { TransitionService } from '@uirouter/core';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ResizeDelta } from 'core-app/shared/components/resizer/resizer.component';
import { fromEvent } from 'rxjs';
import { MainMenuToggleService } from 'core-app/core/main-menu/main-menu-toggle.service';

@Component({
  selector: 'wp-resizer',
  template: `
    <op-resizer [customHandler]="false"
             [resizerClass]="resizerClass"
             cursorClass="col-resize"
             (resizeFinished)="resizeEnd()"
             (resizeStarted)="resizeStart()"
             (move)="resizeMove($event)">
    </op-resizer>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})

export class WpResizerDirective extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  @Input() elementClass:string;

  @Input() resizeEvent:string;

  @Input() localStorageKey:string;

  @Input() variableName:string = '--split-screen-width';

  private resizingElement:HTMLElement;

  private elementWidth:number;

  private element:HTMLElement;

  private resizer:HTMLElement;

  // Min-width this element is allowed to have
  private elementMinWidth = 550;

  public moving = false;

  public resizerClass = 'work-packages--resizer icon-resizer-vertical-lines';

  constructor(
    readonly toggleService:MainMenuToggleService,
    private elementRef:ElementRef,
    readonly $transitions:TransitionService,
  ) {
    super();
  }

  ngOnInit() {
    // Get element
    // We use this more complicated approach of taking the last element of the class as it allows
    // to still work in case an element is duplicated by Angular.
    const elements = document.getElementsByClassName(this.elementClass);
    this.resizingElement = <HTMLElement>elements[elements.length - 1];

    if (!this.resizingElement) {
      return;
    }

    // Get initial width from local storage and apply
    const localStorageValue = this.parseLocalStorageValue();
    this.elementWidth = localStorageValue
                        || (this.resizingElement.offsetWidth < this.elementMinWidth
                          ? this.elementMinWidth
                          : this.resizingElement.offsetWidth);

    // This case only happens when the timeline is loaded but not displayed.
    // Therefor the flexbasis will be set to 50%, just in px
    if (this.elementWidth === 0 && this.resizingElement.parentElement) {
      this.elementWidth = this.resizingElement.parentElement.offsetWidth / 2;
    }

    this.setWidthVariable(this.elementWidth);

    // Add event listener
    this.element = this.elementRef.nativeElement;

    // Listen on sidebar changes and toggle column layout, if necessary
    this.toggleService.changeData$
      .pipe(
        distinctUntilChanged(),
        this.untilDestroyed(),
        debounceTime(100),
      )
      .subscribe(() => {
        this.applyColumnLayout();
      });

    // Listen to event
    fromEvent(window, 'resize', { passive: true })
      .pipe(
        this.untilDestroyed(),
        debounceTime(250),
      )
      .subscribe(() => this.applyColumnLayout());
  }

  ngAfterViewInit():void {
    // Get the reziser
    this.resizer = <HTMLElement> this.elementRef.nativeElement.getElementsByClassName(this.resizerClass)[0];

    this.applyColumnLayout();
  }

  ngOnDestroy() {
    super.ngOnDestroy();
  }

  resizeStart() {
    // In case we dragged the resizer farther than the element can actually grow,
    // we reset it to the actual width at the start of the new resizing
    const localStorageValue = this.parseLocalStorageValue();
    const actualElementWidth = this.resizingElement.offsetWidth;
    if (localStorageValue && localStorageValue > actualElementWidth) {
      this.elementWidth = actualElementWidth;
    }
  }

  resizeEnd() {
    const localStorageValue = this.parseLocalStorageValue();
    if (localStorageValue) {
      this.elementWidth = localStorageValue;
    }

    // Send a event that we resized this element
    const event = new Event(this.resizeEvent);
    window.dispatchEvent(event);

    this.manageErrorClass(false);
  }

  resizeMove(deltas:ResizeDelta) {
    // Get new value depending on the delta
    this.elementWidth -= deltas.relative.x;
    let newValue;

    // The resizingElement is not allowed to be smaller than the elementMinWidth
    if (this.elementWidth < this.elementMinWidth) {
      newValue = this.elementMinWidth;

      // Show the resizer red when it reaches its limit (min-width)
      this.manageErrorClass(true);
    } else {
      newValue = this.elementWidth;

      this.manageErrorClass(false);
    }

    // Store item in local storage
    window.OpenProject.guardedLocalStorage(this.localStorageKey, `${newValue}`);

    // Apply two column layout
    this.applyColumnLayout();

    // Set new width
    this.setWidthVariable(newValue);
  }

  private parseLocalStorageValue():number|undefined {
    const localStorageValue = window.OpenProject.guardedLocalStorage(this.localStorageKey);
    const number = parseInt(localStorageValue || '', 10);

    if (typeof number === 'number' && !Number.isNaN(number)) {
      return number;
    }

    return undefined;
  }
  private applyColumnLayout(checkWidth = 750) {
    const singleView = document.querySelectorAll("[data-selector='wp-single-view']")[0] as HTMLElement;
    if (singleView) {
      jQuery(singleView).toggleClass('work-package--single-view_with-columns', singleView.offsetWidth > checkWidth);
    }
  }

  private manageErrorClass(shouldBePresent:boolean) {
    if (shouldBePresent && !this.resizer.classList.contains('-error-font')) {
      this.resizer.classList.add('-error-font');
    }

    if (!shouldBePresent && this.resizer.classList.contains('-error-font')) {
      this.resizer.classList.remove('-error-font');
    }
  }

  private setWidthVariable(value:number):void {
    document.documentElement.style.setProperty(this.variableName, `${value}px`);
  }
}
