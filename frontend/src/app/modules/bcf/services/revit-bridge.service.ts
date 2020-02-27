import {ViewerBridgeServiceInterface} from "core-app/modules/bcf/services/viewer-bridge.service";

declare global {
  interface Window { RevitBridge:any; }
}

import {Injectable} from '@angular/core';
import {Subject} from "rxjs";
import {distinctUntilChanged, filter, first} from "rxjs/operators";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";

@Injectable()
export class RevitBridgeService implements ViewerBridgeServiceInterface {
  private revitMessageReceivedSource = new Subject<{ messageType:string, trackingId:string, messagePayload:string }>();
  public revitMessageReceived$ = this.revitMessageReceivedSource.asObservable();
  private _trackingIdNumber = 0;
  private _ready = false;

  public get ready() {
    return this._ready;
  }

  constructor() {
    if (window.RevitBridge) {
      console.log("window.RevitBridge is already there, so let's hook up the Revit Listener");
      this.hookUpRevitListener();
    } else {
      console.log('Waiting for Revit Plugin to become ready.');
      window.addEventListener('revit.plugin.ready', () => {
        console.log('CAPTURED EVENT "revit.plugin.ready"');
        this.hookUpRevitListener();
      });
    }
  }

  public getViewpoint():Promise<any> {
    const trackingId = this.newTrackingId();

    this.sendMessageToRevit('ViewpointGenerationRequest', trackingId, '');

    return this.revitMessageReceived$
      .pipe(
        distinctUntilChanged(),
        filter(message => message.messageType === 'ViewpointData' && message.trackingId === trackingId),
        first()
      )
      .toPromise();
  }

  public sendMessageToRevit(messageType:string, trackingId:string, messagePayload?:any) {
    if (!this.ready) {
      console.log('The Revit bridge is not ready yet.');
      return;
    }

    const jsonPayload = messagePayload != null ? JSON.stringify(messagePayload) : null;
    window.RevitBridge.sendMessageToRevit(messageType, trackingId, jsonPayload);
  }

  private hookUpRevitListener() {
    window.RevitBridge.sendMessageToOpenProject = (messageString:string) => {
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
