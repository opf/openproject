import {Inject, Injectable} from '@angular/core';
import {DOCUMENT} from "@angular/common";

@Injectable()
export class BcfDetectorService {
  constructor (@Inject(DOCUMENT) private documentElement:Document) {
  }

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
