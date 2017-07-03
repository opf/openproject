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

import {wpButtonsModule} from '../../../angular-modules';
import {
  ButtonControllerText, WorkPackageButtonController,
  wpButtonDirective
} from '../wp-buttons.module';
import { WorkPackageTableTimelineService } from "../../wp-fast-table/state/wp-table-timeline.service";
import {zoomLevelOrder} from "../../wp-table/timeline/wp-timeline";
import {TimelineZoomLevel} from "../../api/api-v3/hal-resources/query-resource.service";

interface TimelineButtonText extends ButtonControllerText {
  zoomOut:string;
  zoomIn:string;
}

export class WorkPackageTimelineButtonController extends WorkPackageButtonController {
  public buttonId:string = 'work-packages-timeline-toggle-button';
  public iconClass:string = 'icon-view-timeline';

  private activateLabel:string;
  private deactivateLabel:string;

  public text:TimelineButtonText;

  public minZoomLevel:TimelineZoomLevel = 'days';
  public maxZoomLevel:TimelineZoomLevel = 'years';

  constructor(public I18n:op.I18n, public wpTableTimeline:WorkPackageTableTimelineService) {
    'ngInject';
    super(I18n);

    this.activateLabel = I18n.t('js.timelines.button_activate');
    this.deactivateLabel = I18n.t('js.timelines.button_deactivate');

    this.text.zoomIn = I18n.t('js.timelines.zoom.in');
    this.text.zoomOut = I18n.t('js.timelines.zoom.out');
  }

  public get label():string {
    if (this.isActive()) {
      return this.deactivateLabel;
    } else {
      return this.activateLabel;
    }
  }

  public isToggle():boolean {
    return true;
  }

  public isActive():boolean {
    return this.wpTableTimeline.isVisible;
  }

  public updateZoom(delta:number) {
    this.wpTableTimeline.updateZoom(delta);
  }

  public get currentZoom() {
    return this.wpTableTimeline.zoomLevel;
  }

  public performAction() {
    this.toggleTimeline();
  }

  public toggleTimeline() {
    this.wpTableTimeline.toggle();
  }
}

function wpTimelineToggleButton():ng.IDirective {
  return wpButtonDirective({
    require: '^wpTimelineContainer',
    templateUrl: '/components/wp-buttons/wp-timeline-toggle-button/wp-timeline-toggle-button.html',
    controller: WorkPackageTimelineButtonController
  });
}

wpButtonsModule.directive('wpTimelineToggleButton', wpTimelineToggleButton);
