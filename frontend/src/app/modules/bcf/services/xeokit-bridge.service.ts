import {ViewerBridgeServiceInterface} from "core-app/modules/bcf/services/viewer-bridge.service";

import {Injectable} from '@angular/core';
import {IFCViewerService} from "core-app/modules/ifc_models/ifc-viewer/ifc-viewer.service";

@Injectable()
export class XeokitBridgeService implements ViewerBridgeServiceInterface {
  constructor(readonly ifcViewerService:IFCViewerService) {
  }

  public getViewpoint():Promise<any> {
    console.log("getViewpoint from ifcViewerService.getViewer()", this.xeokitViewerService.getViewer());
    return new Promise((resolve, reject) => {});
  }
}
