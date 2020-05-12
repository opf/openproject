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

import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostListener,
  OnDestroy,
  OnInit,
  ViewChild
} from '@angular/core';
import {IFCViewerService} from "core-app/modules/bim/ifc_models/ifc-viewer/ifc-viewer.service";
import {IfcModelsDataService} from "core-app/modules/bim/ifc_models/pages/viewer/ifc-models-data.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  selector: 'ifc-viewer',
  templateUrl: './ifc-viewer.component.html',
  styleUrls: ['./ifc-viewer.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class IFCViewerComponent implements OnInit, OnDestroy {
  private viewerUI:any;
  modelCount:number;
  canManage = this.ifcData.allowed('manage_ifc_models');

  text = {
    empty_warning: this.I18n.t('js.ifc_models.empty_warning'),
    use_this_link_to_manage: this.I18n.t('js.ifc_models.use_this_link_to_manage'),
    keyboard_input_disabled: this.I18n.t('js.ifc_models.keyboard_input_disabled')
  };

  keyboardEnabled = false;

  @ViewChild('outerContainer') outerContainer:ElementRef;
  @ViewChild('modelCanvas') modelCanvas:ElementRef;

  constructor(private I18n:I18nService,
              private elementRef:ElementRef,
              public ifcData:IfcModelsDataService,
              private ifcViewer:IFCViewerService) {
  }

  ngOnInit():void {
    this.modelCount = this.ifcData.models.length;

    if (this.modelCount === 0) {
      return;
    }

    const element = jQuery(this.elementRef.nativeElement as HTMLElement);

    this.ifcViewer.newViewer(
      {
        canvasElement: element.find(".ifc-model-viewer--model-canvas")[0], // WebGL canvas
        explorerElement: jQuery(".ifc-model-viewer--tree-panel")[0], // Left panel
        toolbarElement: element.find(".ifc-model-viewer--toolbar-container")[0], // Toolbar
        navCubeCanvasElement: element.find(".ifc-model-viewer--nav-cube-canvas")[0],
        busyModelBackdropElement: element.find(".xeokit-busy-modal-backdrop")[0]
      },
      this.ifcData.projects
    );
  }

  ngOnDestroy():void {
    this.ifcViewer.destroy();
  }

  @HostListener('mousedown')
  enableKeyBoard() {
    if (this.modelCount) {
      this.keyboardEnabled = true;
      this.ifcViewer.setKeyboardEnabled(true);
    }
  }

  @HostListener('window:mousedown', ['$event.target'])
  disableKeyboard(target:Element) {
    if (this.modelCount && !this.outerContainer.nativeElement!.contains(target)) {
      this.keyboardEnabled = false;
      this.ifcViewer.setKeyboardEnabled(false);
    }
  }

  enableFromIcon(event:MouseEvent) {
    this.enableKeyBoard();

    // Focus on the canvas
    this.modelCanvas.nativeElement.focus();

    // Ensure we don't bubble this event to the window:mousedown handler
    // as the target will already be removed from the DOM by angular
    event.stopImmediatePropagation();
    return false;
  }
}
