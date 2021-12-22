import { Title } from '@angular/platform-browser';
import { Injectable } from '@angular/core';

const titlePartsSeparator = ' | ';

@Injectable({ providedIn: 'root' })
export class OpTitleService {
  constructor(private titleService:Title) {

  }

  public get current():string {
    return this.titleService.getTitle();
  }

  public get titleParts():string[] {
    return this.current.split(titlePartsSeparator);
  }

  public setFirstPart(value:string) {
    const parts = this.titleParts;
    parts[0] = value;

    this.titleService.setTitle(parts.join(titlePartsSeparator));
  }

  public setTitle(value:string):void {
    this.titleService.setTitle(value);
  }

  public removeFirstPart():void {
    // Here we remove the title of current route
    const parts = this.current.split(titlePartsSeparator);
    parts.shift();
    this.titleService.setTitle(parts.join(titlePartsSeparator));
  }

  public getLastTitle():string {
    // Here we get the title of last route
    const parts = this.current.split(titlePartsSeparator);
    if (parts.length > 2) {
      parts.shift();
    }
    return parts.join(' | ');
  }
}
