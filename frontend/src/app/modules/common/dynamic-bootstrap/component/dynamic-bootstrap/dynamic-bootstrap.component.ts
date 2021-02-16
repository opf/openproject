import {ApplicationRef, Component, ElementRef, Input} from '@angular/core';
import {DomSanitizer, SafeHtml} from "@angular/platform-browser";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Component({
  selector: 'op-dynamic-bootstrap',
  templateUrl: './dynamic-bootstrap.component.html',
})
export class DynamicBootstrapComponent {
  /*
  * HTML string to be rendered. Angular components and directives present
  * will be bootstrapped dynamically.
  */
  @Input()
  set HTML(templateString:string) {
    this.innerHtml = this.domSanitizer.bypassSecurityTrustHtml(templateString);
    this.dynamicBootstrapper.bootstrapOptionalEmbeddable(this.appRef, this.elementRef.nativeElement);
  }

  innerHtml:SafeHtml;
  dynamicBootstrapper = DynamicBootstrapper;

  constructor(
    readonly domSanitizer:DomSanitizer,
    readonly elementRef:ElementRef,
    readonly appRef:ApplicationRef,
  ) { }
}
