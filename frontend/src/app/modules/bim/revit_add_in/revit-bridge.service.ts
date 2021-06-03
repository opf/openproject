import { Injectable, Injector } from '@angular/core';
import { Observable, Subject, BehaviorSubject } from "rxjs";
import { distinctUntilChanged, filter, first, map, mapTo } from "rxjs/operators";
import { BcfViewpointInterface } from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";
import { ViewerBridgeService } from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { ViewpointsService } from "core-app/modules/bim/bcf/helper/viewpoints.service";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";


declare global {
  interface Window {
    RevitBridge:any;
  }
}

@Injectable()
export class RevitBridgeService extends ViewerBridgeService {
  public shouldShowViewer = false;
  public viewerVisible$ = new BehaviorSubject<boolean>(false);
  private revitMessageReceivedSource = new Subject<{ messageType:string, trackingId:string, messagePayload:any }>();
  private trackingIdNumber = 0;

  @InjectField() viewpointsService:ViewpointsService;

  revitMessageReceived$ = this.revitMessageReceivedSource.asObservable();

  constructor(readonly injector:Injector) {
    super(injector);

    if (window.RevitBridge) {
      this.hookUpRevitListener();
    } else {
      window.addEventListener('revit.plugin.ready', () => {
        this.hookUpRevitListener();
      }, { once: true });
    }
  }

  public viewerVisible() {
    return this.viewerVisible$.getValue();
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
          const viewpointJson = message.messagePayload;

          viewpointJson.snapshot = {
            snapshot_type: 'png',
            snapshot_data: viewpointJson.snapshot,
          };

          return viewpointJson;
        })
      );
  }

  public showViewpoint(workPackage:WorkPackageResource, index:number) {
    this.viewpointsService
      .getViewPoint$(workPackage, index)
      .subscribe((viewpoint:BcfViewpointInterface) =>  this.sendMessageToRevit('ShowViewpoint', this.newTrackingId(), JSON.stringify(viewpoint)));
  }

  sendMessageToRevit(messageType:string, trackingId:string, messagePayload?:any) {
    if (!this.viewerVisible()) {
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
    this.viewerVisible$.next(true);
  }

  newTrackingId():string {
    this.trackingIdNumber = this.trackingIdNumber + 1;
    return String(this.trackingIdNumber);
  }
}
