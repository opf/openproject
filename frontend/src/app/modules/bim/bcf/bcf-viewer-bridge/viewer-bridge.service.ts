import {Injector, Injectable} from '@angular/core';
import {BcfViewpointInterface} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";
import {Observable} from "rxjs";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";


@Injectable()
export abstract class ViewerBridgeService {
  constructor(readonly injector:Injector) {}

  /**
   * Get a viewpoint from the viewer
   */
  abstract getViewpoint$():Observable<BcfViewpointInterface>;

  /**
   * Show the given viewpoint JSON in the viewer
   * @param viewpoint
   */
  abstract showViewpoint(workPackage:WorkPackageResource, index:number):void;

  /**
   * Determine whether a viewer is present to ensure we can show viewpoints
   */
  abstract viewerVisible():boolean;

  /**
   * Load event
   */
  abstract onLoad$():Observable<void>;
}
