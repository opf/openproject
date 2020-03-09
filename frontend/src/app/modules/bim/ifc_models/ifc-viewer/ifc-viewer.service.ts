import {Injectable} from '@angular/core';
import {XeokitServer} from "core-app/modules/bim/ifc_models/xeokit/xeokit-server";
import {BcfViewpointInterface} from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";

export interface XeokitElements {
  canvasElement:HTMLElement;
  explorerElement:HTMLElement;
  toolbarElement:HTMLElement;
  navCubeCanvasElement:HTMLElement;
  sectionPlanesOverviewCanvasElement:HTMLElement;
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
export class IFCViewerService {
  private viewer:any;

  public newViewer(elements:XeokitElements, projects:any[]) {
    import('@xeokit/xeokit-viewer/dist/main').then((XeokitViewerModule:any) => {
      let server = new XeokitServer();
      let viewerUI = new XeokitViewerModule.BIMViewer(server, elements);

      viewerUI.on("queryPicked", (event:any) => {
        const entity = event.entity; // Entity
        const metaObject = event.metaObject; // MetaObject
        alert(`Query result:\n\nObject ID = ${entity.id}\nIFC type = "${metaObject.type}"`);
      });

      viewerUI.loadProject(projects[0]["id"]);

      this.viewer = viewerUI;
    });
  }

  public destroy() {
    if (!this.viewer) {
      return;
    }

    this.viewer._bcfViewpointsPlugin.destroy();
    this.viewer._canvasContextMenu.destroy();
    this.viewer._objectContextMenu.destroy();

    while (this.viewer.viewer._plugins.length > 0) {
      const plugin = this.viewer.viewer._plugins[0];
      plugin.destroy();
    }

    this.viewer.viewer.scene.destroy();
    this.viewer = undefined;
  }

  public saveBCFViewpoint(options:BCFCreationOptions = {}):BcfViewpointInterface {
    return this.viewer.saveBCFViewpoint(options);
  }

  public loadBCFViewpoint(viewpoint:BcfViewpointInterface, options:BCFLoadOptions = {}) {
    this.viewer.loadBCFViewpoint(viewpoint, options);
  }

  public viewerVisible():boolean {
    return !!this.viewer;
  }
}
