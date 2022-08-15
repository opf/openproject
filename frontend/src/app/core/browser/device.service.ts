import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class DeviceService {
  public get isMobile():boolean {
    return window.matchMedia('(max-width: 679px)').matches;
  }

  constructor() {
    window.addEventListener('resize', () => {
      this.isMobile$.next(this.isMobile);
    });
  }

  public isMobile$ = new BehaviorSubject<boolean>(this.isMobile);
}
