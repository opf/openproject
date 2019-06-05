import {Inject, Injectable} from "@angular/core";
import {DOCUMENT} from "@angular/common";

@Injectable()
export class BrowserDetector {

  constructor (@Inject(DOCUMENT) private documentElement:Document) {
  }

  /**
   * Detect mobile browser based on the Rails determined UA
   * and resulting body class.
   */
  public get isMobile() {
    return this.hasBodyClass('-browser-mobile');
  }

  public get isEdge() {
    return this.hasBodyClass('-browser-edge');
  }

  private hasBodyClass(name:string):boolean {
    return this.documentElement.body.classList.contains(name);
  }

}
