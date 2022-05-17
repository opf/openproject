import { Injectable, Injector } from '@angular/core';
import { Observable } from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { StateService } from '@uirouter/core';
import { CreateBcfViewpointData } from 'core-app/features/bim/bcf/api/bcf-api.model';

@Injectable()
export abstract class ViewerBridgeService {
  @InjectField() state:StateService;

  /**
   * Determine whether a viewer should be shown
   */
  abstract shouldShowViewer:boolean;

  protected constructor(readonly injector:Injector) {}

  /**
   * Get a viewpoint from the viewer
   */
  abstract getViewpoint$():Observable<CreateBcfViewpointData>;

  /**
   * Show the given viewpoint JSON in the viewer
   */
  abstract showViewpoint(workPackage:WorkPackageResource, index:number):void;

  /**
   * Determine whether a viewer is present to ensure we can show viewpoints
   */
  abstract viewerVisible():boolean;

  /**
   * Fires when viewer becomes visible.
   */
  abstract viewerVisible$:Observable<boolean>;
}
