import {
  AfterViewInit,
  Directive,
  ElementRef,
  Input,
} from '@angular/core';
import { FocusHelperService } from './focus-helper';

@Directive({
  selector: '[opAutofocus]',
})
export class AutofocusDirective implements AfterViewInit {
  @Input('opAutofocus') public condition = true;

  @Input('opAutofocusPriority') priority?:number = 0;

  constructor(
    readonly FocusHelper:FocusHelperService,
    readonly elementRef:ElementRef,
  ) { }

  ngAfterViewInit() {
    this.updateFocus();
  }

  private updateFocus() {
    if (this.condition) {
      const element = jQuery(this.elementRef.nativeElement);
      this.FocusHelper.focusElement(element, this.priority);
    }
  }
}
