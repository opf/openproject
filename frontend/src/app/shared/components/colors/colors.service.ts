import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ColorsService {
  public toHsl(value:string) {
    const mode = document.body.getAttribute('data-light-theme');
    return `hsl(${this.valueHash(value)}, 50%, ${mode === 'light_high_contrast' ? '30%' : '50%'})`;
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
}
