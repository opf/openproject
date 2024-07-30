//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, Injector } from '@angular/core';
import { XeokitServer } from 'core-app/features/bim/ifc_models/xeokit/xeokit-server';
import { ViewerBridgeService } from 'core-app/features/bim/bcf/bcf-viewer-bridge/viewer-bridge.service';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { BcfApiService } from 'core-app/features/bim/bcf/api/bcf-api.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { ViewpointsService } from 'core-app/features/bim/bcf/helper/viewpoints.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { HttpClient } from '@angular/common/http';
import { IfcProjectDefinition } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-models-data.service';
import { BIMViewer } from '@xeokit/xeokit-bim-viewer/dist/xeokit-bim-viewer.es';
import { BcfViewpointData, CreateBcfViewpointData } from 'core-app/features/bim/bcf/api/bcf-api.model';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

export interface XeokitElements {
  canvasElement:HTMLElement;
  explorerElement:HTMLElement;
  toolbarElement:HTMLElement;
  inspectorElement:HTMLElement;
  navCubeCanvasElement:HTMLElement;
  busyModelBackdropElement:HTMLElement;
  enableEditModels?:boolean;
  keyboardEventsElement?:HTMLElement;
  enableMeasurements?:boolean;
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

/**
 * Wrapping type from xeokit module. Can be removed after we get a real type package.
 */
type Controller = {
  on:(event:string, callback:(event:unknown) => void) => string
};

/**
 * Wrapping type from xeokit module. Can be removed after we get a real type package.
 */
type XeokitBimViewer = Controller&{
  loadProject:(projectId:string) => void,
  saveBCFViewpoint:(options:BCFCreationOptions) => unknown,
  loadBCFViewpoint:(bcfViewpoint:BcfViewpointData, options:BCFLoadOptions) => void,
  setKeyboardEnabled:(enabled:boolean) => true,
  destroy:() => void
};

@Injectable()
export class IFCViewerService extends ViewerBridgeService {
  public shouldShowViewer = true;

  public viewerVisible$ = new BehaviorSubject<boolean>(false);

  public inspectorVisible$ = new BehaviorSubject<boolean>(false);

  private xeokitViewer:XeokitBimViewer|undefined;

  @InjectField() pathHelper:PathHelperService;

  @InjectField() bcfApi:BcfApiService;

  @InjectField() viewpointsService:ViewpointsService;

  @InjectField() currentProjectService:CurrentProjectService;

  @InjectField() httpClient:HttpClient;

  constructor(readonly injector:Injector) {
    super(injector);
  }

  public newViewer(elements:XeokitElements, projects:IfcProjectDefinition[]):void {
    const server = new XeokitServer(this.pathHelper);
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    const viewerUI = new BIMViewer(server, elements) as XeokitBimViewer;

    viewerUI.on('modelLoaded', () => this.viewerVisible$.next(true));

    viewerUI.loadProject(projects[0].id);

    viewerUI.on('addModel', () => { // "Add" selected in Models tab's context menu
      window.location.href = this.pathHelper.ifcModelsNewPath(this.currentProjectService.identifier as string);
    });

    viewerUI.on('openInspector', () => {
      this.inspectorVisible$.next(true);
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
        this.pathHelper.ifcModelsDeletePath(this.currentProjectService.identifier as string, event.modelId),
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
  }

  public destroy():void {
    this.viewerVisible$.next(false);

    if (!this.viewer) {
      return;
    }

    this.viewer.destroy();
    this.viewer = undefined;
  }

  public get viewer():XeokitBimViewer|undefined {
    return this.xeokitViewer;
  }

  public set viewer(viewer:XeokitBimViewer|undefined) {
    this.xeokitViewer = viewer;
  }

  public setKeyboardEnabled(val:boolean):void {
    this.viewer?.setKeyboardEnabled(val);
  }

  public getViewpoint$():Observable<CreateBcfViewpointData> {
    if (!this.viewer) {
      return of();
    }

    const opts:BCFCreationOptions = { spacesVisible: true, reverseClippingPlanes: true };
    const viewpoint = this.viewer.saveBCFViewpoint(opts) as CreateBcfViewpointData;

    // project output of viewer to ensured BCF viewpoint format
    const bcfViewpoint:CreateBcfViewpointData = {
      // The backend currently rejects viewpoints with bitmaps
      bitmaps: null,
      clipping_planes: viewpoint.clipping_planes,
      index: viewpoint.index,
      guid: viewpoint.guid,
      components: {
        selection: viewpoint.components.selection,
        coloring: viewpoint.components.coloring,
        visibility: {
          default_visibility: viewpoint.components.visibility.default_visibility,
          exceptions: viewpoint.components.visibility.exceptions,
          view_setup_hints: {
            openings_visible: viewpoint.components.visibility.view_setup_hints?.openings_visible || false,
            space_boundaries_visible: viewpoint.components.visibility.view_setup_hints?.space_boundaries_visible || false,
            spaces_visible: viewpoint.components.visibility.view_setup_hints?.spaces_visible || false,
          },
        },
      },
      lines: viewpoint.lines,
      orthogonal_camera: viewpoint.orthogonal_camera,
      perspective_camera: viewpoint.perspective_camera,
      snapshot: viewpoint.snapshot,
    };

    return of(bcfViewpoint);
  }

  public showViewpoint(workPackage:WorkPackageResource, index:number):void {
    if (this.viewerVisible()) {
      const opts:BCFLoadOptions = { updateCompositeObjects: true, reverseClippingPlanes: true };
      this.viewpointsService
        .getViewPoint$(workPackage, index)
        .subscribe((viewpoint) => {
          this.viewer?.loadBCFViewpoint(viewpoint, opts);
        });
    } else {
      // FIXME: When triggering showViewpoint from anywhere outside BCF module, there is no viewer shown and we have
      //  no means of setting it from here. Hence we must make a hard transition to bcf details route of the
      //  current work package.
      window.location.href = this.pathHelper.bimDetailsPath(
        idFromLink((workPackage.project as HalResource).href),
        workPackage.id || '',
        index,
      );
    }
  }

  public viewerVisible():boolean {
    return !!this.viewer;
  }
}
