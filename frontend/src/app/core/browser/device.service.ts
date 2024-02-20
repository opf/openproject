import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class DeviceService {
  public mobileWidthThreshold = 544;
  public smallDesktopWidthThreshold = 1012;

  public get isMobile():boolean {
    return (window.innerWidth < this.mobileWidthThreshold);
  }

  public get isSmallDesktop():boolean {
    return (window.innerWidth < this.smallDesktopWidthThreshold);
  }
}
