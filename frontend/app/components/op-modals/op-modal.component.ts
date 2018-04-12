import {ElementRef, OnInit} from '@angular/core';
import {OpModalLocalsMap} from 'core-components/op-modals/op-modal.types';
import {OpModalService} from 'core-components/op-modals/op-modal.service';

export abstract class OpModalComponent implements OnInit {

  /* Close on escape? */
  public closeOnEscape:boolean = true;

  /* Close on outside click */
  public closeOnOutsideClick:boolean = true;

  /* Reference to service */
  protected service:OpModalService = this.locals.service;

  public $element:JQuery;

  constructor(public locals:OpModalLocalsMap, readonly elementRef:ElementRef) {
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
  }

  /**
   * Called when the user attempts to close the modal window.
   * The service will close this modal if this method returns true
   * @returns {boolean}
   */
  public onClose():boolean {
    this.afterFocusOn.focus();
    return true;
  }

  public closeMe() {
    this.service.close();
  }

  public onOpen(modalElement:JQuery) {
  }

  protected get afterFocusOn():JQuery {
    return this.$element;
  }
}
