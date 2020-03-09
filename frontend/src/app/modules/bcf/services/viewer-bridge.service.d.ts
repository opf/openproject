import {BcfViewpointInterface} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";

export interface ViewerBridgeServiceInterface {
  getViewpoint():Promise<BcfViewpointInterface>;

  showViewpoint(viewpoint:BcfViewpointInterface):void;
}
