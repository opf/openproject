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

import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostListener,
  OnDestroy,
  OnInit,
  ViewChild,
} from '@angular/core';
import { IFCViewerService } from 'core-app/features/bim/ifc_models/ifc-viewer/ifc-viewer.service';
import { IfcModelsDataService } from 'core-app/features/bim/ifc_models/pages/viewer/ifc-models-data.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import {
  BehaviorSubject,
  combineLatest,
  Subject, Subscription,
} from 'rxjs';
import { filter, take } from 'rxjs/operators';

@Component({
  selector: 'op-ifc-viewer',
  templateUrl: './ifc-viewer.component.html',
  styleUrls: ['./ifc-viewer.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class IFCViewerComponent implements OnInit, OnDestroy, AfterViewInit {
  private viewInitialized$ = new Subject<void>();

  modelCount:number = this.ifcData.models.length;

  canManage = this.ifcData.allowed('manage_ifc_models');

  text = {
    empty_warning: this.I18n.t('js.ifc_models.empty_warning'),
    use_this_link_to_manage: this.I18n.t('js.ifc_models.use_this_link_to_manage'),
    keyboard_input_disabled: this.I18n.t('js.ifc_models.keyboard_input_disabled'),
  };

  keyboardEnabled = false;

  inspectorVisible$:BehaviorSubject<boolean> = this.ifcViewerService.inspectorVisible$;

  @ViewChild('outerContainer') outerContainer:ElementRef;

  @ViewChild('viewerContainer') viewerContainer:ElementRef;

  @ViewChild('modelCanvas') modelCanvas:ElementRef;

  @ViewChild('navCubeCanvas') navCubeCanvas:ElementRef;

  @ViewChild('toolbar') toolbarElement:ElementRef;

  @ViewChild('inspectorPane') inspectorElement:ElementRef;

  @ViewChild('xeokitToolbarIcons') xeokitToolbarIcons:ElementRef;

  constructor(
    public ifcData:IfcModelsDataService,
    private I18n:I18nService,
    private ifcViewerService:IFCViewerService,
    private currentUserService:CurrentUserService,
    private currentProjectService:CurrentProjectService,
  ) { }

  ngOnInit():void {
    if (this.modelCount === 0) {
      return;
    }

    // we have to wait until view is initialized before constructing the ifc viewer,
    // as it needs all view children ready and rendered
    combineLatest([
      this
        .currentUserService
        .hasCapabilities$(
          [
            'ifc_models/create',
            'ifc_models/update',
            'ifc_models/destroy',
          ],
          this.currentProjectService.id as string,
        ),
      this.viewInitialized$,
    ])
      .pipe(take(1))
      .subscribe(([manageIfcModelsAllowed]) => {
        this.ifcViewerService.newViewer(
          {
            canvasElement: this.modelCanvas.nativeElement as HTMLElement,
            explorerElement: document.getElementsByClassName('op-ifc-viewer--tree-panel')[0] as HTMLElement, // Left panel
            toolbarElement: this.toolbarElement.nativeElement as HTMLElement,
            inspectorElement: this.inspectorElement.nativeElement as HTMLElement,
            navCubeCanvasElement: this.navCubeCanvas.nativeElement as HTMLElement,
            busyModelBackdropElement: this.viewerContainer.nativeElement as HTMLElement,
            keyboardEventsElement: this.modelCanvas.nativeElement as HTMLElement,
            enableEditModels: manageIfcModelsAllowed,
            enableMeasurements: false,
          },
          this.ifcData.projects,
        );
      });

    this.insertXeokitToolbarIcons();
  }

  /**
   * Inserts xeokit toolbar icons into each element. We need to render buttons with the octicon svg, hide the button
   * container and insert the rendered SVG into the toolbar elements.
   * This is necessary, as we do not use the xeokit icon font, but want to have a consistent look and feel of
   * interaction elements with icons.
   * @private
   */
  private insertXeokitToolbarIcons():Subscription {
    return this.ifcViewerService.viewerVisible$
      .pipe(
        filter((visible) => visible),
        take(1),
      )
      .subscribe(() => {
        const toolbarIcons = this.xeokitToolbarIcons.nativeElement as HTMLElement;
        const toolbar = this.toolbarElement.nativeElement as HTMLElement;

        for (let i = 0; i < toolbarIcons.children.length; i++) {
          const replacer = toolbarIcons.children[i];
          const target = replacer.id.replace('xeokit-replace-', '');

          const targetElement = toolbar.querySelector(`.xeokit-btn.xeokit-${target}`);
          if (targetElement !== null) {
            targetElement.insertAdjacentHTML('afterbegin', replacer.innerHTML);
          }
        }
      });
  }

  ngAfterViewInit():void {
    this.viewInitialized$.next();
  }

  ngOnDestroy():void {
    this.ifcViewerService.destroy();
  }

  toggleInspector():void {
    this.ifcViewerService.inspectorVisible$.next(!this.inspectorVisible$.getValue());
  }

  // Key events for navigating the viewer shall not propagate further up in the DOM, i.e.
  // pressing the S-key shall not trigger the global search which listens on `document`.
  @HostListener('keydown', ['$event'])
  @HostListener('keyup', ['$event'])
  @HostListener('keypress', ['$event'])
  // eslint-disable-next-line class-methods-use-this
  cancelAllKeyEvents($event:KeyboardEvent):void {
    $event.stopPropagation();
  }

  @HostListener('mousedown')
  enableKeyBoard():void {
    if (this.modelCount) {
      this.keyboardEnabled = true;
      this.ifcViewerService.setKeyboardEnabled(true);
    }
  }

  @HostListener('window:mousedown', ['$event.target'])
  disableKeyboard(target:Element):void {
    if (this.modelCount && !(this.outerContainer.nativeElement as HTMLElement).contains(target)) {
      this.keyboardEnabled = false;
      this.ifcViewerService.setKeyboardEnabled(false);
    }
  }

  enableFromIcon(event:MouseEvent):boolean {
    this.enableKeyBoard();

    // Focus on the canvas
    (this.modelCanvas.nativeElement as HTMLElement).focus();

    // Ensure we don't bubble this event to the window:mousedown handler
    // as the target will already be removed from the DOM by angular
    event.stopImmediatePropagation();
    return false;
  }
}
