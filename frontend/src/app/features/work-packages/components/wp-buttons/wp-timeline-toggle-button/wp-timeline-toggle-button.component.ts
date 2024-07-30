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
  ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { TimelineZoomLevel } from 'core-app/features/hal/resources/query-resource';
import { AbstractWorkPackageButtonComponent, ButtonControllerText } from '../wp-buttons.module';

export interface TimelineButtonText extends ButtonControllerText {
  zoomOut:string;
  zoomIn:string;
  zoomAuto:string;
}

@Component({
  templateUrl: './wp-timeline-toggle-button.html',
  styleUrls: ['./wp-timeline-toggle-button.sass'],
  selector: 'wp-timeline-toggle-button',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageTimelineButtonComponent extends AbstractWorkPackageButtonComponent implements OnInit {
  public buttonId = 'work-packages-timeline-toggle-button';

  public iconClass = 'icon-view-timeline';

  private activateLabel:string;

  private deactivateLabel:string;

  public text:TimelineButtonText;

  public minZoomLevel:TimelineZoomLevel = 'days';

  public maxZoomLevel:TimelineZoomLevel = 'years';

  public isAutoZoom = false;

  public isMaxLevel = false;

  public isMinLevel = false;

  constructor(readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
    public wpTableTimeline:WorkPackageViewTimelineService) {
    super(I18n);

    this.activateLabel = I18n.t('js.gantt_chart.button_activate');
    this.deactivateLabel = I18n.t('js.gantt_chart.button_deactivate');

    this.text.zoomIn = I18n.t('js.gantt_chart.zoom.in');
    this.text.zoomOut = I18n.t('js.gantt_chart.zoom.out');
    this.text.zoomAuto = I18n.t('js.gantt_chart.zoom.auto');
  }

  ngOnInit():void {
    this.wpTableTimeline
      .live$()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe(() => {
        this.isAutoZoom = this.wpTableTimeline.isAutoZoom();
        this.isActive = this.wpTableTimeline.isVisible;
        this.cdRef.detectChanges();
      });

    this.wpTableTimeline
      .appliedZoomLevel$
      .values$()
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe((current) => {
        this.isMaxLevel = current === this.maxZoomLevel;
        this.isMinLevel = current === this.minZoomLevel;
        this.cdRef.detectChanges();
      });
  }

  public get label():string {
    if (this.isActive) {
      return this.deactivateLabel;
    }
    return this.activateLabel;
  }

  public isToggle():boolean {
    return true;
  }

  public updateZoomWithDelta(delta:number) {
    this.wpTableTimeline.updateZoomWithDelta(delta);
  }

  public performAction(event:Event) {
    this.toggleTimeline();
  }

  public toggleTimeline() {
    this.wpTableTimeline.toggle();
  }

  public enableAutoZoom() {
    this.wpTableTimeline.enableAutozoom();
  }

  public getAutoZoomToggleClass():string {
    return this.isAutoZoom ? '-disabled' : '';
  }
}
