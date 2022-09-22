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

  constructor(
    readonly FocusHelper:FocusHelperService,
    readonly elementRef:ElementRef,
  ) { }

  ngAfterViewInit() {
    this.updateFocus();
  }

  private updateFocus() {
    if (this.condition) {
      this.FocusHelper.focus(this.elementRef.nativeElement);
    }
  }
}
