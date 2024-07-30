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

import { ChangeDetectorRef, Directive, ElementRef, EventEmitter, Inject, OnDestroy, OnInit } from '@angular/core';

import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { OpModalLocalsToken, OpModalService } from 'core-app/shared/components/modal/modal.service';
import { debounce } from 'lodash';

@Directive()
export abstract class OpModalComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  /* Reference to service */
  protected service:OpModalService = this.locals.service;

  public $element:HTMLElement;

  /** Closing event called from the service when closing this modal */
  public closingEvent = new EventEmitter<this>();

  public openingEvent = new EventEmitter<this>();

  /** Whether we want to hide the show close button. Used to hide when rendering primer */
  showCloseButton = true;

  /* Data to be return from this modal instance */
  public data:unknown;

  protected constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
  ) {
    super();
  }

  ngOnInit():void {
    this.$element = this.elementRef.nativeElement as HTMLElement;
  }

  ngOnDestroy():void {
    this.closingEvent.complete();
    this.openingEvent.complete();
    window.removeEventListener('resize', this.onResize);
    window.removeEventListener('orientationchange', this.onResize);
  }

  /**
   * Called when the user attempts to close the modal window.
   * The service will close this modal if this method returns true
   * @returns {boolean}
   */
  public onClose():boolean {
    this.afterFocusOn && this.afterFocusOn.focus();
    return true;
  }

  public closeMe(evt?:Event):void {
    this.service.close();

    if (evt) {
      evt.stopPropagation();
      evt.preventDefault();
    }
  }

  public onOpen():void {
    this.openingEvent.emit();
    this.updateAppHeight();
    this.cdRef.detectChanges();

    window.addEventListener('resize', this.onResize);
    window.addEventListener('orientationchange', this.onResize);
  }

  protected get afterFocusOn():HTMLElement {
    return this.$element;
  }

  private onResize = debounce(() => this.updateAppHeight(), 10);

  private updateAppHeight = () =>
    document
      .documentElement
      .style
      .setProperty('--app-height', `${window.innerHeight}px`);
}
