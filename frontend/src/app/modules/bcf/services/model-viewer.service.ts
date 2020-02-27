import {HostListener, Injectable} from '@angular/core';
import {ViewerBridgeServiceInterface} from "core-app/modules/bcf/services/viewer-bridge.service";
import {RevitBridgeService} from "core-app/modules/bcf/services/revit-bridge.service";
import {XeokitBridgeService} from "core-app/modules/bcf/services/xeokit-bridge.service";

@Injectable()
export class ModelViewerService {

  public modelViewer:ViewerBridgeServiceInterface;


  constructor(private readonly revitBridge:RevitBridgeService,
              private readonly xeokitBridge:XeokitBridgeService) {
    this.modelViewer = this.revitBridge;
    if (window.navigator.userAgent.search('Revit') > -1) {
      console.log("We are running in the context of a revit add-in");
      this.modelViewer = this.revitBridge;
    } else {
      console.log('We are running in a plain browser');
      this.modelViewer = this.xeokitBridge;
    }
  }

  public getViewpoint():Promise<any> {
    return this.modelViewer.getViewpoint();
  }
}
