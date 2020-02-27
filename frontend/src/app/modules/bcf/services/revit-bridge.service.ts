declare global {
  interface Window { bcfierBridge:any; }
}

import {HostListener, Injectable} from '@angular/core';
import {Subject} from "rxjs";

@Injectable()
export class RevitBridgeService {
  private revitMessageReceivedSource = new Subject<{ messageType:string, trackingId:string, messagePayload:string }>();
  public revitMessageReceived$ = this.revitMessageReceivedSource.asObservable();
  private _trackingIdNumber = 0;
  private _ready = false;

  public get ready() {
    return this._ready;
  }

  @HostListener('window:revit.client.loaded')
  onRevitClientLoaded() {
    console.log('EVENT onRevitClientLoaded');
    this.hookUpRevitListener();
  }

  constructor() {
    if (window.bcfierBridge) {
      this.hookUpRevitListener();
    }
  }

  public sendMessageToRevit(messageType:string, trackingId:string, messagePayload?:any) {
    if (!this.ready) {
      console.log('The BCFier Revit Bridge is not ready yet.');
      return;
    }

    const jsonPayload = messagePayload != null ? JSON.stringify(messagePayload) : null;
    window.bcfierBridge.sendMessageToBcfier(messageType, trackingId, jsonPayload);
  }

  private hookUpRevitListener() {
    window.bcfierBridge.sendMessageToOpenProject = (messageString:string) => {
      const message = JSON.parse(messageString);
      const messageType = message.messageType;
      const trackingId = message.trackingId;
      const messagePayload = JSON.parse(message.messagePayload);

      this.revitMessageReceivedSource.next({
        messageType: messageType,
        trackingId: trackingId,
        messagePayload: messagePayload
      });
    };
    this._ready = true;
  }

  public newTrackingId():string {
    this._trackingIdNumber = this._trackingIdNumber + 1;
    return String(this._trackingIdNumber);
  }
}
