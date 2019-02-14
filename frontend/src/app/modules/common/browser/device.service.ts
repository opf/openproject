import {Injectable} from '@angular/core';

@Injectable()
export class DeviceService {

  public mobileWidthTreshold:number = 680;

  constructor() {}

  public get isMobile():boolean {
    return (window.innerWidth < this.mobileWidthTreshold);
  }
}
