import {Injectable} from '@angular/core';
import {XeokitServer} from "core-app/modules/bim/ifc_models/xeokit/xeokit-server";
import {BcfViewpointInterface} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";
import {ViewerBridgeService} from "core-app/modules/bim/bcf/bcf-viewer-bridge/viewer-bridge.service";
import {Observable, Subject} from "rxjs";

export interface XeokitElements {
  canvasElement:HTMLElement;
  explorerElement:HTMLElement;
  toolbarElement:HTMLElement;
  navCubeCanvasElement:HTMLElement;
  busyModelBackdropElement:HTMLElement;
}

export interface BCFCreationOptions {
  spacesVisible?:boolean;
  spaceBoundariesVisible?:boolean;
  openingsVisible?:boolean;
}

export interface BCFLoadOptions {
  rayCast?:boolean;
  immediate?:boolean;
  duration?:number;
}

@Injectable()
export class IFCViewerService extends ViewerBridgeService {
  private _viewer:any;

  private $loaded = new Subject<void>();

  public newViewer(elements:XeokitElements, projects:any[]) {
    import('@xeokit/xeokit-bim-viewer/dist/main').then((XeokitViewerModule:any) => {
      let server = new XeokitServer();
      let viewerUI = new XeokitViewerModule.BIMViewer(server, elements);

      viewerUI.on("queryPicked", (event:any) => {
        alert(`IFC Name = "${event.objectName}"\nIFC class = "${event.objectType}"\nIFC GUID = ${event.objectId}`);
      });

      viewerUI.on("modelLoaded", () => this.$loaded.complete());

      viewerUI.loadProject(projects[0]["id"]);

      this.viewer = viewerUI;
    });
  }

  public destroy() {
    this.$loaded.complete();

    if (!this.viewer) {
      return;
    }

    this.viewer.destroy();
    this.viewer = undefined;
  }

  public get viewer() {
    return this._viewer;
  }

  public set viewer(viewer:any) {
    this._viewer = viewer;
  }

  public setKeyboardEnabled(val:boolean) {
    this.viewer.setKeyboardEnabled(val);
  }

  public getViewpoint():Promise<BcfViewpointInterface> {
    const viewpoint = this.viewer.saveBCFViewpoint({ spacesVisible: true });

    // The backend rejects viewpoints with bitmaps
    delete viewpoint.bitmaps;

    return Promise.resolve(viewpoint);
  }

  public showViewpoint(viewpoint:BcfViewpointInterface) {
    if (this.viewerVisible()) {
      this.viewer.loadBCFViewpoint(viewpoint, {});
    }
  }

  public viewerVisible():boolean {
    return !!this.viewer;
  }

  public onLoad$():Observable<void> {
    return this.$loaded;
  }
}
