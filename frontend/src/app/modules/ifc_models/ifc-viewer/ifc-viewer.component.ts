// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {Component, ElementRef, OnInit, OnDestroy, ChangeDetectionStrategy} from '@angular/core';
import {GonService} from "core-app/modules/common/gon/gon.service";
import {IFCViewerService} from "core-app/modules/ifc_models/ifc-viewer/ifc-viewer.service";

@Component({
  selector: 'ifc-viewer',
  template: `
    <div class="ifc-model-viewer--container">
      <div class="ifc-model-viewer--toolbar-container"></div>
      <canvas class="ifc-model-viewer--model-canvas"></canvas>
    </div>

    <canvas class="ifc-model-viewer--nav-cube-canvas"></canvas>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IFCViewerComponent implements OnInit, OnDestroy {
  private viewerUI:any;

  constructor(private Gon:GonService,
              private elementRef:ElementRef,
              private ifcViewer:IFCViewerService) {
  }

  ngOnInit():void {
    const element = jQuery(this.elementRef.nativeElement as HTMLElement);

    this.ifcViewer.newViewer(
      {
        canvasElement: element.find(".ifc-model-viewer--model-canvas")[0], // WebGL canvas
        explorerElement: jQuery(".ifc-model-viewer--tree-panel")[0], // Left panel
        toolbarElement: element.find(".ifc-model-viewer--toolbar-container")[0], // Toolbar
        navCubeCanvasElement: element.find(".ifc-model-viewer--nav-cube-canvas")[0],
        sectionPlanesOverviewCanvasElement: element.find(".ifc-model-viewer--section-planes-overview-canvas")[0]
      },
      this.Gon.get('ifc_models', 'projects') as any[]
    );
  }

  ngOnDestroy():void {
    this.ifcViewer.destroy();
  }
}
