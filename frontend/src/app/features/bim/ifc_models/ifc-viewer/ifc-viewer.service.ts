import { Injectable, Injector } from '@angular/core';
import { XeokitServer } from 'core-app/features/bim/ifc_models/xeokit/xeokit-server';
import { BcfViewpointInterface } from 'core-app/features/bim/bcf/api/viewpoints/bcf-viewpoint.interface';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { BcfApiService } from 'core-app/features/bim/bcf/api/bcf-api.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { ViewpointsService } from 'core-app/features/bim/bcf/helper/viewpoints.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { HttpClient } from '@angular/common/http';


export interface XeokitElements {
  canvasElement:HTMLElement;
  explorerElement:HTMLElement;
  toolbarElement:HTMLElement;
  navCubeCanvasElement:HTMLElement;
  busyModelBackdropElement:HTMLElement;
  enableEditModels?:boolean;
}

/**
 * Options for saving current viewpoint in xeokit-bim-viewer.
 * See: https://xeokit.github.io/xeokit-bim-viewer/docs/class/src/BIMViewer.js~BIMViewer.html#instance-method-saveBCFViewpoint
 */
export interface BCFCreationOptions {
  spacesVisible?:boolean;
  spaceBoundariesVisible?:boolean;
  openingsVisible?:boolean;
  defaultInvisible?:boolean;
  reverseClippingPlanes?:boolean;
}

/**
 * Options for loading a viewpoint into xeokit-bim-viewer.
 * See: https://xeokit.github.io/xeokit-bim-viewer/docs/class/src/BIMViewer.js~BIMViewer.html#instance-method-loadBCFViewpoint
 */
export interface BCFLoadOptions {
  rayCast?:boolean;
  immediate?:boolean;
  duration?:number;
  updateCompositeObjects?:boolean;
  reverseClippingPlanes?:boolean;
}

@Injectable()
export class IFCViewerService extends ViewerBridgeService {
  public shouldShowViewer = true;

  public viewerVisible$ = new BehaviorSubject<boolean>(false);

  private _viewer:any;

  @InjectField() pathHelper:PathHelperService;

  @InjectField() bcfApi:BcfApiService;

  @InjectField() viewpointsService:ViewpointsService;

  @InjectField() currentProjectService:CurrentProjectService;

  @InjectField() httpClient:HttpClient;

  constructor(readonly injector:Injector) {
    super(injector);
  }

  public newViewer(elements:XeokitElements, projects:any[]):void {
    import('@xeokit/xeokit-bim-viewer/dist/xeokit-bim-viewer.es').then((XeokitViewerModule:any) => {
      const server = new XeokitServer(this.pathHelper);
      const viewerUI = new XeokitViewerModule.BIMViewer(server, elements);

      viewerUI.on('queryPicked', (event:any) => {
        alert(`IFC Name = "${event.objectName}"\nIFC class = "${event.objectType}"\nIFC GUID = ${event.objectId}`);
      });

      viewerUI.on('modelLoaded', () => this.viewerVisible$.next(true));

      viewerUI.loadProject(projects[0].id);

      viewerUI.on('addModel', (event:Event) => { // "Add" selected in Models tab's context menu
        window.location.href = this.pathHelper.ifcModelsNewPath(this.currentProjectService.identifier as string);
      });

      viewerUI.on('editModel', (event:{ modelId:number|string }) => { // "Edit" selected in Models tab's context menu
        window.location.href = this.pathHelper.ifcModelsEditPath(this.currentProjectService.identifier as string, event.modelId);
      });

      viewerUI.on('deleteModel', (event:{ modelId:number|string }) => { // "Delete" selected in Models tab's context menu
        // We don't have an API for IFC models yet. We need to use the normal Rails form posts for deletion.
        const formData = new FormData();
        formData.append(
          'authenticity_token',
          jQuery('meta[name=csrf-token]').attr('content') as string,
        );
        formData.append(
          '_method',
          'delete',
        );

        this.httpClient.post(
          this.pathHelper.ifcModelsDeletePath(
            this.currentProjectService.identifier as string, event.modelId,
          ),
          formData,
        )
          .subscribe()
          .add(() => {
            // Ensure we reload after every request.
            // We need to reload to get a fresh CSRF token for a successive
            // model deletion placed as a META element into the HTML HEAD.
            window.location.reload();
          });
      });

      this.viewer = viewerUI;
    });
  }

  public destroy():void {
    this.viewerVisible$.complete();

    if (!this.viewer) {
      return;
    }

    this.viewer.destroy();
    this.viewer = undefined;
  }

  public get viewer():any {
    return this._viewer;
  }

  public set viewer(viewer:any) {
    this._viewer = viewer;
  }

  public setKeyboardEnabled(val:boolean):void {
    this.viewer.setKeyboardEnabled(val);
  }

  public getViewpoint$():Observable<BcfViewpointInterface> {
    const opts:BCFCreationOptions = { spacesVisible: true, reverseClippingPlanes: true };
    const viewpoint = this.viewer.saveBCFViewpoint(opts);

    // The backend rejects viewpoints with bitmaps
    delete viewpoint.bitmaps;

    return of(viewpoint);
  }

  public showViewpoint(workPackage:WorkPackageResource, index:number):void {
    // Avoid reload the app when there is a place to show the viewer
    // ('bim.partitioned.split')
    if (this.routeWithViewer) {
      if (this.viewer) {
        const opts:BCFLoadOptions = { updateCompositeObjects: true, reverseClippingPlanes: true };
        this.viewpointsService
          .getViewPoint$(workPackage, index)
          .subscribe(viewpoint => this.viewer.loadBCFViewpoint(viewpoint, opts));
      }
    } else {
      // Reload the whole app to get the correct menus and GON data
      // and redirect to a route with a place to show viewer
      // ('bim.partitioned.split')
      window.location.href = this.pathHelper.bimDetailsPath(
        workPackage.project.idFromLink,
        workPackage.id!,
        index,
      );
    }
  }

  public viewerVisible():boolean {
    return !!this.viewer;
  }
}
