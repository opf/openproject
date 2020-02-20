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

import {Injectable} from '@angular/core';
import {QueryResource, TimelineLabels, TimelineZoomLevel} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {input} from 'reactivestates';
import {WorkPackageQueryStateService} from './wp-view-base.service';
import {WorkPackageTimelineState} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-table-timeline";
import {zoomLevelOrder} from "core-components/wp-table/timeline/wp-timeline";

@Injectable()
export class WorkPackageViewTimelineService extends WorkPackageQueryStateService<WorkPackageTimelineState> {

  /** Remember the computed zoom level to correct zooming after leaving autozoom */
  public appliedZoomLevel$ = input<TimelineZoomLevel>('auto');

  public constructor(protected readonly querySpace:IsolatedQuerySpace) {
    super(querySpace);
  }

  public valueFromQuery(query:QueryResource) {
    return {
      ...this.defaultState,
      visible: query.timelineVisible,
      zoomLevel: query.timelineZoomLevel,
      labels: query.timelineLabels
    };
  }

  public set appliedZoomLevel(val:TimelineZoomLevel) {
    this.appliedZoomLevel$.putValue(val);
  }

  public get appliedZoomLevel() {
    return this.appliedZoomLevel$.value!;
  }

  public hasChanged(query:QueryResource) {
    const visibilityChanged = this.isVisible !== query.timelineVisible;
    const zoomLevelChanged = this.zoomLevel !== query.timelineZoomLevel;
    const labelsChanged = !_.isEqual(this.current.labels, query.timelineLabels);

    return visibilityChanged || zoomLevelChanged || labelsChanged;
  }

  public applyToQuery(query:QueryResource) {
    query.timelineVisible = this.isVisible;
    query.timelineZoomLevel = this.zoomLevel;
    query.timelineLabels = this.current.labels;

    return false;
  }

  public toggle() {
    let currentState = this.current;
    this.setVisible(!currentState.visible);
  }

  public setVisible(value:boolean) {
    this.updatesState.putValue({...this.current, visible: value});
  }

  public get isVisible() {
    return this.current.visible;
  }

  public get zoomLevel() {
    return this.current.zoomLevel;
  }

  public get labels() {
    if (_.isEmpty(this.current.labels)) {
      return this.defaultLabels;
    }

    return this.current.labels;
  }

  public updateLabels(labels:TimelineLabels) {
    this.modify({ labels: labels });
  }

  public getNormalizedLabels(workPackage:WorkPackageResource) {
    let labels:TimelineLabels = this.defaultLabels;

    _.each(this.current.labels, (attribute:string | null, positionAsString:string) => {
      // RR: Lodash typings declare the position as string. However, it is save to cast
      // to `keyof TimelineLabels` because `this.current.labels` is of type TimelineLabels.
      const position:keyof TimelineLabels = positionAsString as keyof TimelineLabels;

      // Set to null to explicitly disable
      if (attribute === '') {
        labels[position] = null;
      } else {
        labels[position] = attribute;
      }
    });

    return labels;
  }

  public setZoomLevel(level:TimelineZoomLevel) {
    this.modify({ zoomLevel: level });
  }

  public updateZoomWithDelta(delta:number):void {
    let level = this.current.zoomLevel;
    if (level !== 'auto') {
      return this.applyZoomLevel(level, delta);
    }

    const applied = this.appliedZoomLevel;
    if (applied && applied !== 'auto') {
      // When we have a real zoom value, use delta on that one
      this.applyZoomLevel(applied, delta);
    } else {
      // Use the maximum zoom value
      const target = delta < 0 ? 'days' : 'years';
      this.setZoomLevel(target);
    }
  }

  public isAutoZoom():boolean {
    return this.current.zoomLevel === 'auto';
  }

  public enableAutozoom() {
    this.modify({ zoomLevel: "auto" });
  }

  public get current():WorkPackageTimelineState {
    return this.lastUpdatedState.getValueOr(this.defaultState);
  }

  /**
   * Modify the state, updating with parts of properties
   * @param update
   */
  private modify(update:Partial<WorkPackageTimelineState>) {
    this.update({ ...this.current, ...update } as WorkPackageTimelineState);
  }

  /**
   * Apply a zoom level
   *
   * @param level Any zoom level except auto.
   * @param delta The delta (e.g., 1, -1) to apply.
   */
  private applyZoomLevel(level:Exclude<TimelineZoomLevel, 'auto'>, delta:number) {
    let idx = zoomLevelOrder.indexOf(level);
    idx += delta;

    if (idx >= 0 && idx < zoomLevelOrder.length) {
      this.setZoomLevel(zoomLevelOrder[idx]);
    }
  }

  private get defaultLabels():TimelineLabels {
    return {
      left: '',
      right: '',
      farRight: 'subject'
    };
  }

  private get defaultState():WorkPackageTimelineState {
    return {
      zoomLevel: 'auto',
      visible: false,
      labels: this.defaultLabels
    };
  }
}
