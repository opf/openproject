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

import {Component, Input, OnDestroy, OnInit, ViewEncapsulation} from '@angular/core';
import {DynamicBootstrapper} from "app/globals/dynamic-bootstrapper";

import {XeokitServer} from "./xeokit-server";
import {ViewerUI} from "@xeokit/xeokit-viewer/src/ViewerUI";

import InspireTree from "inspire-tree";
import InspireTreeDOM from "inspire-tree-dom";

@Component({
  selector: 'ifc-viewer',
  template: `
  <canvas [id]="'xeokit-model-canvas-' + ifcModelId" class="xeokit-model-canvas"></canvas>
`,
  styleUrls: [
    '../../../../node_modules/inspire-tree-dom/dist/inspire-tree-light.css'
  ],
  encapsulation: ViewEncapsulation.None
})
export class IFCViewerComponent implements OnInit, OnDestroy {
  @Input() public ifcModelId:string;
  @Input() public xktFileUrl:string;
  @Input() public metadataFileUrl:string;

  ngOnInit():void {
    // @ts-ignore "declare module" for some weird reason not working.
    import('@xeokit/xeokit-viewer/src/ViewerUI').then((XeokitViewerModule:any) => {
      let server = new XeokitServer();
      // let viewer = new XeokitViewerModule.XeokitViewer(this.ifcModelId, this.xktFileUrl, this.metadataFileUrl);
    });
  }

  ngOnDestroy():void {
  }
}
DynamicBootstrapper.register({
  selector: 'ifc-viewer', cls: IFCViewerComponent
});