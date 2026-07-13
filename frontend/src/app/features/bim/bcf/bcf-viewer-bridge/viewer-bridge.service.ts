import { Injectable, Injector, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { StateService } from '@uirouter/core';
import { CreateBcfViewpointData } from 'core-app/features/bim/bcf/api/bcf-api.model';

@Injectable()
export abstract class ViewerBridgeService {
  readonly injector = inject(Injector);

  @LazyInject() state:StateService;

  /**
   * Determine whether a viewer should be shown
   */
  abstract shouldShowViewer:boolean;

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
