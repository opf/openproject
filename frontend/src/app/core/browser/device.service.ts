import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class DeviceService {
  public mobileWidthTreshold = 544;

  public get isMobile():boolean {
    return (window.innerWidth < this.mobileWidthTreshold);
  }
}
