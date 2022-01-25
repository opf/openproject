import { Injectable, Injector } from '@angular/core';
import { Observable, Subject, BehaviorSubject } from "rxjs";
import { distinctUntilChanged, filter, first, map } from "rxjs/operators";
import { BcfViewpointInterface } from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";
import { ViewerBridgeService } from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { ViewpointsService } from "core-app/modules/bim/bcf/helper/viewpoints.service";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";


declare global {
  interface Window {
    RevitBridge:{
      sendMessageToRevit:(messageType:string, trackingId:string, payload:string) => void,
      sendMessageToOpenProject:(message:string) => void
    };
  }
}

@Injectable()
export class RevitBridgeService extends ViewerBridgeService {
  public shouldShowViewer = false;
  public viewerVisible$ = new BehaviorSubject<boolean>(false);
  private revitMessageReceivedSource =
    new Subject<{ messageType:string, trackingId:string, messagePayload:BcfViewpointInterface }>();
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

  public viewerVisible():boolean {
    return this.viewerVisible$.getValue();
  }

  public getViewpoint$():Observable<BcfViewpointInterface> {
    const trackingId = this.newTrackingId();

    this.sendMessageToRevit('ViewpointGenerationRequest', trackingId, '');

    return this.revitMessageReceived$
      .pipe(
        distinctUntilChanged(),
        filter(message => message.messageType === 'ViewpointData' && message.trackingId === trackingId),
        first(),
        map((message) => {
          // FIXME: Deprecated code
          // the handling of the message payload is only needed to be compatible to the revit add-in <= 2.3.2. In
          // newer versions the message payload is sent correctly and needs no special treatment
          const viewpointJson = message.messagePayload;

          if (viewpointJson.snapshot.hasOwnProperty('snapshot_type') &&
            viewpointJson.snapshot.hasOwnProperty('snapshot_data')) {
            // already correctly formatted payload
            return viewpointJson;
          }

          // at this point snapshot data should be sent as a base64 string
          viewpointJson.snapshot = {
            snapshot_type: 'png',
            snapshot_data: viewpointJson.snapshot as unknown as string,
          };

          return viewpointJson;
        }),
      );
  }

  public showViewpoint(workPackage:WorkPackageResource, index:number):void {
    this.viewpointsService
      .getViewPoint$(workPackage, index)
      .subscribe((viewpoint:BcfViewpointInterface) =>
        this.sendMessageToRevit(
          'ShowViewpoint',
          this.newTrackingId(),
          JSON.stringify(viewpoint),
        ),
      );
  }

  sendMessageToRevit(messageType:string, trackingId:string, messagePayload:string):void {
    if (!this.viewerVisible()) {
      return;
    }

    window.RevitBridge.sendMessageToRevit(messageType, trackingId, messagePayload);
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
        messagePayload: messagePayload,
      });
    };
    this.viewerVisible$.next(true);
  }

  newTrackingId():string {
    this.trackingIdNumber = this.trackingIdNumber + 1;
    return String(this.trackingIdNumber);
  }
}
