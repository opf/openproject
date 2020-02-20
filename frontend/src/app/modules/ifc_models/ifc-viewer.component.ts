// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

/// <reference path="xeokit.d.ts" />

import {Component, ElementRef, Input, OnDestroy, OnInit, ViewEncapsulation} from '@angular/core';
import {DynamicBootstrapper} from "app/globals/dynamic-bootstrapper";

import {XeokitServer} from "./xeokit-server";
import {GonService} from "core-app/modules/common/gon/gon.service";

@Component({
  selector: 'ifc-viewer',
  template: `
<div class="ifc-model-viewer--container">
    <div class="ifc-model-viewer--toolbar-container"></div>
    <canvas class="ifc-model-viewer--model-canvas"></canvas>
</div>

<canvas class="ifc-model-viewer--nav-cube-canvas"></canvas>
`
})
export class IFCViewerComponent implements OnInit {
  constructor(private Gon:GonService,
              private elementRef:ElementRef) {
  }

  ngOnInit():void {
    const element = jQuery(this.elementRef.nativeElement as HTMLElement);

    import('@xeokit/xeokit-viewer/dist/main').then((XeokitViewerModule:any) => {
      let server = new XeokitServer();
      let viewerUI = new XeokitViewerModule.BIMViewer(server, {
        canvasElement: element.find(".ifc-model-viewer--model-canvas")[0], // WebGL canvas
        explorerElement: jQuery(".ifc-model-viewer--tree-panel")[0], // Left panel
        toolbarElement: element.find(".ifc-model-viewer--toolbar-container")[0], // Toolbar
        navCubeCanvasElement: element.find(".ifc-model-viewer--nav-cube-canvas")[0],
        sectionPlanesOverviewCanvasElement: element.find(".ifc-model-viewer--section-planes-overview-canvas")[0]
      });

      viewerUI.on("queryPicked", (event:any) => {
        const entity = event.entity; // Entity
        const metaObject = event.metaObject; // MetaObject
        alert(`Query result:\n\nObject ID = ${entity.id}\nIFC type = "${metaObject.type}"`);
      });

      viewerUI.loadProject(this.Gon.get('ifc_models', 'projects') as any [0]["id"]);
    });
  }
}
DynamicBootstrapper.register({
  selector: 'ifc-viewer', cls: IFCViewerComponent
});