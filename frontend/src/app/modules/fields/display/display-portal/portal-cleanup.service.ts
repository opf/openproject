import {Injectable} from '@angular/core';


@Injectable()
export class PortalCleanupService {

  public portalCallbacks:Function[] = [];

  public add(callback:Function) {
    this.portalCallbacks.push(callback);
  }

  public clear() {
    this.portalCallbacks.forEach((callback) => callback());
    this.portalCallbacks = [];
  }
}
