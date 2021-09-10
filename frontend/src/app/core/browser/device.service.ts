import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class DeviceService {
  public mobileWidthTreshold = 680;

  public tabletWidthTreshold = 1249;

  public get isMobile():boolean {
    return (window.innerWidth < this.mobileWidthTreshold);
  }

  public get isTablet():boolean {
    return (window.innerWidth < this.tabletWidthTreshold);
  }
}
