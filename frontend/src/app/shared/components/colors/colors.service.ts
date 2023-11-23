import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ColorsService {
  public toHsl(value:string) {
    return `hsl(${this.valueHash(value)}, 50%, 50%)`;
  }

  public toHslDark(value:string) {
    return `hsl(${this.valueHash(value)}, 50%, 30%)`;
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
