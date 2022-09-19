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
  @Input('opAutofocus') public condition:string|boolean = true;

  constructor(
    readonly FocusHelper:FocusHelperService,
    readonly elementRef:ElementRef,
  ) { }

  ngAfterViewInit():void {
    this.updateFocus();
  }

  private updateFocus():void {
    // Empty string should count as true because just using the directive like the
    // plain HTML autofocus attribute should be possible:
    //
    // <my-input opAutofocus />
    //
    if (this.condition || this.condition === '') {
      this.FocusHelper.focus(this.elementRef.nativeElement);
    }
  }
}
