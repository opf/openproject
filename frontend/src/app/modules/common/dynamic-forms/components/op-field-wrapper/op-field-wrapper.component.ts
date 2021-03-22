import { ChangeDetectorRef, Component, ElementRef, HostListener, NgZone, OnInit } from "@angular/core";
import { FieldWrapper } from "@ngx-formly/core";

@Component({
  selector: "op-field-wrapper",
  templateUrl: "./op-field-wrapper.component.html",
  styleUrls: ["./op-field-wrapper.component.scss"]
})
export class OpFieldWrapperComponent extends FieldWrapper {
  @HostListener("click")
  onClick() {
    this.focused = true;
    this.changeDetectorRef.detectChanges();
    const input = this.elementRef?.nativeElement?.querySelector('input') || this.elementRef?.nativeElement?.querySelector('textarea');

    input?.focus();
  }
  @HostListener("document:mousedown", ["$event.target"])
  onBlur(target:HTMLElement) {
    if (!this.elementRef?.nativeElement?.contains(target)) {
      this.focused = false;
    }
  }

  focused: boolean;

  constructor(
    private elementRef: ElementRef,
    private changeDetectorRef:ChangeDetectorRef,
  ) {
    super();
  }
}
