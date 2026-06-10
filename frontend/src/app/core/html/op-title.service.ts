import { Title } from '@angular/platform-browser';
import { Injectable, inject } from '@angular/core';
import { getMetaContent } from '../setup/globals/global-helpers';

const titlePartsSeparator = ' | ';

@Injectable({ providedIn: 'root' })
export class OpTitleService {
  private titleService = inject(Title);


  public get current():string {
    return this.titleService.getTitle();
  }

  public get base():string {
    return getMetaContent('app_title');
  }

  public get titleParts():string[] {
    return this.current.split(titlePartsSeparator);
  }

  public get appTitle():string {
    return this.titleParts[this.titleParts.length - 1];
  }

  public setFirstPart(value:string) {
    if (this.current.includes(this.base) && this.current.includes(titlePartsSeparator)) {
      const parts = this.titleParts;
      parts[0] = value;
      this.titleService.setTitle(parts.join(titlePartsSeparator));
    } else {
      const newTitle = [value, this.base].join(titlePartsSeparator);
      this.titleService.setTitle(newTitle);
    }
  }
}
