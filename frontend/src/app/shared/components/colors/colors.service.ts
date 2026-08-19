import { Injectable } from '@angular/core';

export const colorModes = {
  lightHighContrast: 'lightHighContrast',
  light: 'light',
  dark: 'dark',
};

@Injectable({ providedIn: 'root' })
export class ColorsService {
  public toHsl(value:string):string {
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
    if (document.body.getAttribute('data-color-mode') === 'dark') {
      return colorModes.dark;
    }

    if (document.body.getAttribute('data-light-theme') === 'light_high_contrast') {
      return colorModes.lightHighContrast;
    }

    return colorModes.light;
  }
}
