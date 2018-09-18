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

import {Injectable} from '@angular/core';
import {QueryResource, TimelineLabels, TimelineZoomLevel} from 'core-app/modules/hal/resources/query-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {InputState} from 'reactivestates';
import {zoomLevelOrder} from '../../wp-table/timeline/wp-timeline';
import {WorkPackageTableTimelineState} from './../wp-table-timeline';
import {WorkPackageQueryStateService, WorkPackageTableBaseService} from './wp-table-base.service';

@Injectable()
export class WorkPackageTableTimelineService extends WorkPackageTableBaseService<WorkPackageTableTimelineState> implements WorkPackageQueryStateService {

  public constructor(tableState:TableState) {
    super(tableState);
  }


  public get state():InputState<WorkPackageTableTimelineState> {
    return this.tableState.timeline;
  }

  public valueFromQuery(query:QueryResource) {
    return new WorkPackageTableTimelineState(query);
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
    this.setVisible(!currentState.isVisible);
  }

  public setVisible(value:boolean) {
    let currentState = this.current;
    currentState.visible = value;

    this.state.putValue(currentState);
  }

  public get isVisible() {
    return this.current.isVisible;
  }

  public get zoomLevel() {
    return this.current.zoomLevel;
  }

  public get labels() {
    if (_.isEmpty(this.current.labels)) {
      return this.current.defaultLabels;
    }

    return this.current.labels;
  }

  public updateLabels(labels:TimelineLabels) {
    let currentState = this.current;
    currentState.labels = labels;
    this.state.putValue(currentState);
  }

  public getNormalizedLabels(workPackage:WorkPackageResource) {
    let labels:TimelineLabels = _.clone(this.current.defaultLabels);

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
    let currentState = this.current;
    currentState.zoomLevel = level;
    this.state.putValue(currentState);
  }

  public updateZoomWithDelta(delta:number) {
    if (this.isAutoZoomEnabled()) {
      this.toggleAutoZoom();
    }

    let idx = zoomLevelOrder.indexOf(this.current.zoomLevel);
    idx += delta;

    if (idx >= 0 && idx < zoomLevelOrder.length) {
      this.setZoomLevel(zoomLevelOrder[idx]);
    }
  }

  public toggleAutoZoom(value = !this.current.autoZoom) {
    let currentState = this.current;
    currentState.autoZoom = value;
    this.state.putValue(currentState);
  }

  public isAutoZoomEnabled():boolean {
    return this.current.autoZoom;
  }

  public get current():WorkPackageTableTimelineState {
    return this.state.value as WorkPackageTableTimelineState;
  }
}
