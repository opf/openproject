import {ApplicationRef, Component, ElementRef, Input} from '@angular/core';
import {DomSanitizer, SafeHtml} from "@angular/platform-browser";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Component({
  selector: 'op-dynamic-bootstrap',
  templateUrl: './dynamic-bootstrap.component.html',
})
export class DynamicBootstrapComponent {
  @Input()
  set innerHtml(templateString:string) {
    this._innerHtml = this.domSanitizer.bypassSecurityTrustHtml(templateString);
    DynamicBootstrapper.bootstrapOptionalEmbeddable(this.appRef, this.elementRef.nativeElement);
  }

  _innerHtml:SafeHtml;

  constructor(
    protected domSanitizer:DomSanitizer,
    private elementRef:ElementRef,
    protected appRef:ApplicationRef,
  ) { }
}
