import { Injectable, DOCUMENT, inject } from '@angular/core';

@Injectable()
export class BcfDetectorService {
  private documentElement = inject<Document>(DOCUMENT);


  /**
   * Detect whether the BCF module was activated,
   * resulting in a body class.
   */
  public get isBcfActivated() {
    return this.hasBodyClass('bcf-activated');
  }

  private hasBodyClass(name:string):boolean {
    return this.documentElement.body.classList.contains(name);
  }
}
