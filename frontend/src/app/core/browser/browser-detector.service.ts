import { Injectable, DOCUMENT, inject } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class BrowserDetector {
  private documentElement = inject<Document>(DOCUMENT);


  /**
   * Detect mobile browser based on the Rails determined UA
   * and resulting body class.
   */
  public get isMobile() {
    return this.hasBodyClass('-browser-mobile');
  }

  /**
   * ToDo: Remove all occurrences once Edge on Chromium is released
   */
  public get isEdge() {
    return this.hasBodyClass('-browser-edge');
  }

  private hasBodyClass(name:string):boolean {
    return this.documentElement.body.classList.contains(name);
  }
}
