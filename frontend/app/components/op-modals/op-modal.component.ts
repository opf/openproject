import {ElementRef, OnDestroy, OnInit} from '@angular/core';
import {OpModalLocalsMap} from 'core-components/op-modals/op-modal.types';
import {OpModalService} from 'core-components/op-modals/op-modal.service';
import {EventEmitter} from '@angular/core';

export abstract class OpModalComponent implements OnInit, OnDestroy {

  /* Close on escape? */
  public closeOnEscape:boolean = true;

  /* Close on outside click */
  public closeOnOutsideClick:boolean = true;

  /* Reference to service */
  protected service:OpModalService = this.locals.service;

  public $element:JQuery;

  /** Closing event called from the service when closing this modal */
  public closingEvent = new EventEmitter<this>();

  constructor(public locals:OpModalLocalsMap, readonly elementRef:ElementRef) {
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);
  }

  ngOnDestroy() {
    this.closingEvent.complete();
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

  public closeMe(evt:Event) {
    this.service.close(evt);
  }

  public onOpen(modalElement:JQuery) {
  }

  protected get afterFocusOn():JQuery {
    return this.$element;
  }
}
