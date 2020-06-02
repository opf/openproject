import {Injector, Injectable} from '@angular/core';
import {BcfViewpointInterface} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";
import {Observable} from "rxjs";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {StateService} from "@uirouter/core";


@Injectable()
export abstract class ViewerBridgeService {
  @InjectField() state:StateService;
  /**
   * Check if we are on a router state where there is a place
   * where the viewer could be shown
   */
  get routeWithViewer():boolean {
    return this.state.includes('bim.partitioned.split');
  }

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
