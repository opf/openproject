import { AfterViewInit, Directive, ElementRef, Input, inject } from '@angular/core';
import { FocusHelperService } from './focus-helper';

@Directive({
  selector: '[opAutofocus]',
  standalone: false,
})
export class AutofocusDirective implements AfterViewInit {
  readonly FocusHelper = inject(FocusHelperService);
  readonly elementRef = inject(ElementRef);

  @Input('opAutofocus') public condition:string|boolean = true;

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
