import {Injectable, Injector} from '@angular/core';
import {Observable, Subject} from "rxjs";
import {distinctUntilChanged, filter, first, mapTo} from "rxjs/operators";
import {BcfViewpointInterface} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";
import {ViewerBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";
import {input} from "reactivestates";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {ViewpointsService} from "core-app/modules/bim/bcf/helper/viewpoints.service";
import {map} from "rxjs/operators";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";


declare global {
  interface Window {
    RevitBridge:any;
  }
}

@Injectable()
export class RevitBridgeService extends ViewerBridgeService {
  private revitMessageReceivedSource = new Subject<{ messageType:string, trackingId:string, messagePayload:string }>();
  private _trackingIdNumber = 0;
  private _ready$ = input<boolean>(false);

  @InjectField() viewpointsService:ViewpointsService;

  revitMessageReceived$ = this.revitMessageReceivedSource.asObservable();

  constructor(readonly injector:Injector) {
    super(injector);

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

  public viewerVisible() {
    return this._ready$.getValueOr(false);
  }

  public getViewpoint$():Observable<BcfViewpointInterface> {
    const trackingId = this.newTrackingId();

    this.sendMessageToRevit('ViewpointGenerationRequest', trackingId, '');

    return this.revitMessageReceived$
      .pipe(
        distinctUntilChanged(),
        filter(message => message.messageType === 'ViewpointData' && message.trackingId === trackingId),
        first()
      )
      .pipe(
        map((message) => {
          let viewpointJson = JSON.parse(message.messagePayload);

          viewpointJson.snapshot = {
            snapshot_type: 'png',
            snapshot_data: viewpointJson.snapshot
          };
          return viewpointJson;
        })
      )
  }

  public showViewpoint(workPackage:WorkPackageResource, index:number) {
     this.viewpointsService
              .getViewPoint$(workPackage, index)
              .subscribe((viewpoint: BcfViewpointInterface) =>  this.sendMessageToRevit('ShowViewpoint', this.newTrackingId(), JSON.stringify(viewpoint)));
  }

  sendMessageToRevit(messageType:string, trackingId:string, messagePayload?:any) {
    if (!this.viewerVisible()) {
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
    this._ready$.putValue(true);
  }

  newTrackingId():string {
    this._trackingIdNumber = this._trackingIdNumber + 1;
    return String(this._trackingIdNumber);
  }

  onLoad$():Observable<void> {
    return this
      ._ready$
      .values$()
      .pipe(mapTo(undefined));
  }
}
