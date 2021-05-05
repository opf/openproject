import { AfterContentInit, Directive, ElementRef, Input } from '@angular/core';
import { FocusHelperService } from "core-app/modules/common/focus/focus-helper";

@Directive({
  selector: '[autoFocus]'
})
export class AutofocusDirective implements AfterContentInit {
  @Input('autoFocus-condition') public condition = true;

  public constructor(private el:ElementRef,
                     private focusHelper:FocusHelperService) {

  }

  public ngAfterContentInit() {
    if (!this.condition) {
      return;
    }

    setTimeout(() => {
      this.focusHelper.focusElement(jQuery(this.el.nativeElement));
    }, 100);
  }
}
