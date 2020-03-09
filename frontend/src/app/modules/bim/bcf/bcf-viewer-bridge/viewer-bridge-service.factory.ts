import {RevitBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/revit-bridge.service";
import {XeokitBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/xeokit-bridge.service";
import {Injector} from "@angular/core";
import {IFCViewerService} from "core-app/modules/bim/ifc_models/ifc-viewer/ifc-viewer.service";

/**
 * Determines based on the current user agent whether
 * we're running in Revit or not.
 *
 * Depending on that, we use the IFC viewer service for showing/saving viewpoints.
 */
export function viewerBridgeServiceFactory(injector:Injector) {
  if (window.navigator.userAgent.search('Revit') > -1) {
    return new RevitBridgeService();
  } else {
    return new XeokitBridgeService(injector.get(IFCViewerService));
  }
}