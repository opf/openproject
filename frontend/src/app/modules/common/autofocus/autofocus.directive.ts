import {AfterViewInit, Directive, ElementRef, Input} from '@angular/core';

@Directive({
  selector: '[autoFocus]'
})
export class AutofocusDirective implements AfterViewInit {
  private condition:boolean;

  constructor(private elementRef:ElementRef) {
  }

  ngAfterViewInit() {
    if (this.condition && this.elementRef.nativeElement) {
      this.elementRef.nativeElement.focus();
    }
  }

  @Input() set autofocus(condition:boolean) {
    this.condition = condition;
  }
}
