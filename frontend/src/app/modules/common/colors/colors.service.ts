import { Injectable } from '@angular/core';

@Injectable()
export class ColorsService {
  public forString(value:string) {
    let hash = 0;
    for (var i = 0; i < value.length; i++) {
      hash = value.charCodeAt(i) + ((hash << 5) - hash);
    }

    let h = hash % 360;

    return 'hsl(' + h + ', 50%, 50%)';
  }
}