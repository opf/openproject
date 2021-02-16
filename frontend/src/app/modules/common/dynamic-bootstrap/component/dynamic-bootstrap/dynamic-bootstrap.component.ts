import {ApplicationRef, Component, ElementRef, Input} from '@angular/core';
import {DomSanitizer, SafeHtml} from "@angular/platform-browser";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
/**
 * Allows to dynamically render an HTML string into any HTML node, bootstrapping
 * dynamically all its Angular components and directives.
 *
 * @example
 * ```
 *  <op-dynamic-bootstrap HTML="<macro data-id="1" data-detailed="false" title="Macro nº1"></macro>">
 *  </op-dynamic-bootstrap>
 * ```
 * @public
 */
@Component({
  selector: 'op-dynamic-bootstrap',
  templateUrl: './dynamic-bootstrap.component.html',
})
export class DynamicBootstrapComponent {
  /*
  * HTML string to be rendered.
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
