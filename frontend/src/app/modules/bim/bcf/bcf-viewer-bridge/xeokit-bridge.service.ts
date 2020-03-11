import {Injectable} from '@angular/core';
import {IFCViewerService} from "core-app/modules/bim/ifc_models/ifc-viewer/ifc-viewer.service";
import {BcfViewpointInterface} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";
import {ViewerBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";

@Injectable()
export class XeokitBridgeService extends ViewerBridgeService {
  constructor(readonly ifcViewerService:IFCViewerService) {
    super();
  }

  public getViewpoint():Promise<BcfViewpointInterface> {
    const viewpoint = this.ifcViewerService.saveBCFViewpoint();

    // Clean up empty bitmaps array that we do not support
    delete viewpoint['bitmaps'];

    return Promise.resolve(viewpoint);
  }

  public showViewpoint(viewpoint:BcfViewpointInterface):void {
    this.ifcViewerService.loadBCFViewpoint(viewpoint);
  }
}
