import {ViewerBridgeServiceInterface} from "core-app/modules/bcf/services/viewer-bridge.service";

import {Injectable} from '@angular/core';
import {IFCViewerService} from "core-app/modules/bim/ifc_models/ifc-viewer/ifc-viewer.service";

@Injectable()
export class XeokitBridgeService implements ViewerBridgeServiceInterface {
  constructor(readonly ifcViewerService:IFCViewerService) {
  }

  public getViewpoint():Promise<any> {
    return Promise.resolve(this.ifcViewerService.saveBCFViewpoint());
  }
}
