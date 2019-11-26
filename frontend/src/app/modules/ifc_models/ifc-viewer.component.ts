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

import {Component, Input, OnDestroy, OnInit, ViewEncapsulation} from '@angular/core';
import {DynamicBootstrapper} from "app/globals/dynamic-bootstrapper";

import {XeokitServer} from "./xeokit-server";

@Component({
  selector: 'ifc-viewer',
  template: `
<div id="myWrapper">

    <nav id="myExplorer" class="active"></nav>
    <div id="myContent">
        <div id="myToolbar"></div>
        <canvas id="myCanvas"></canvas>
<!--        <canvas [id]="'xeokit-model-canvas-' + ifcModelId" class="xeokit-model-canvas"></canvas>-->
    </div>
</div>

<canvas id="myNavCubeCanvas"></canvas>
<canvas id="mySectionPlanesOverviewCanvas"></canvas>
`,
  styles: [
    // '../../../../node_modules/inspire-tree-dom/dist/inspire-tree-light.css'
  ],
  // encapsulation: ViewEncapsulation.None
})
export class IFCViewerComponent implements OnInit, OnDestroy {
  @Input() public ifcModelId:string;
  @Input() public xktFileUrl:string;
  @Input() public metadataFileUrl:string;

  ngOnInit():void {
    import('@xeokit/xeokit-viewer/dist/main').then((XeokitViewerModule:any) => {
      let server = new XeokitServer();
      let viewerUI = new XeokitViewerModule.ViewerUI(server, {
        canvasElement: document.getElementById("myCanvas"), // WebGL canvas
        explorerElement: document.getElementById("myExplorer"), // Left panel
        toolbarElement: document.getElementById("myToolbar"), // Toolbar
        navCubeCanvasElement: document.getElementById("myNavCubeCanvas"),
        sectionPlanesOverviewCanvasElement: document.getElementById("mySectionPlanesOverviewCanvas")
      });
    });
  }

  ngOnDestroy():void {
  }
}
DynamicBootstrapper.register({
  selector: 'ifc-viewer', cls: IFCViewerComponent
});