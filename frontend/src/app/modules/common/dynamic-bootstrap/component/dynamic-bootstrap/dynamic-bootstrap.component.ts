import {ApplicationRef, Component, ElementRef, Input} from '@angular/core';
import {DomSanitizer, SafeHtml} from "@angular/platform-browser";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Component({
  selector: 'op-dynamic-bootstrap',
  templateUrl: './dynamic-bootstrap.component.html',
})
export class DynamicBootstrapComponent {
  /*
  * HTML string to be rendered, it can contain Angular components and directives.
  */
  @Input()
  set HTML(templateString:string) {
    this.innerHtml = this.domSanitizer.bypassSecurityTrustHtml(templateString);
    DynamicBootstrapper.bootstrapOptionalEmbeddable(this.appRef, this.elementRef.nativeElement);
  }

  innerHtml:SafeHtml;

  constructor(
    protected domSanitizer:DomSanitizer,
    private elementRef:ElementRef,
    protected appRef:ApplicationRef,
  ) { }
}
