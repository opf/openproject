import {BcfViewpointInterface} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";

export abstract class ViewerBridgeService {
  /**
   * Get a viewpoint from the viewer
   */
  abstract getViewpoint():Promise<BcfViewpointInterface>;

  /**
   * Show the given viewpoint JSON in the viewer
   * @param viewpoint
   */
  abstract showViewpoint(viewpoint:BcfViewpointInterface):void;
}
