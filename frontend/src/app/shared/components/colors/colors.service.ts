import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ColorsService {
  public toHsl(value:string, colorMode?:string):string {
    return `hsl(${this.valueHash(value)}, 50%, ${colorMode === 'light_high_contrast' ? '30%' : '50%'})`;
  }

  public toHsla(value:string, opacity:number) {
    return `hsla(${this.valueHash(value)}, 50%, 30%, ${opacity}%)`;
  }

  protected valueHash(value:string) {
    let hash = 0;
    for (let i = 0; i < value.length; i++) {
      hash = value.charCodeAt(i) + ((hash << 5) - hash);
    }

    return hash % 360;
  }

  public colorMode():string {
    return document.body.getAttribute('data-light-theme') ?? 'light';
  }
}
