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

import {
  TableStateStates, WorkPackageQueryStateService,
  WorkPackageTableBaseService
} from "./wp-table-base.service";
import {QueryResource} from "../../api/api-v3/hal-resources/query-resource.service";
import {opServicesModule} from "../../../angular-modules";
import {States} from "../../states.service";
import {WorkPackageTableTimelineState} from "./../wp-table-timeline";
import {zoomLevelOrder} from "../../wp-table/timeline/wp-timeline";

export class WorkPackageTableTimelineService extends WorkPackageTableBaseService implements WorkPackageQueryStateService {
  protected stateName = 'timelineVisible' as TableStateStates;

  constructor(public states:States) {
    super(states);
  }

  public initialize(query:QueryResource) {
    let current = new WorkPackageTableTimelineState(query.timelineVisible, query.timelineZoomLevel);

    this.state.putValue(current);
  }

  public hasChanged(query:QueryResource) {
    const visibilityChanged = this.isVisible !== query.timelineVisible;
    const zoomLevelChanged = this.zoomLevel !== query.timelineZoomLevel;

    return visibilityChanged || zoomLevelChanged;
  }

  public applyToQuery(query:QueryResource) {
    query.timelineVisible = this.isVisible;
    query.timelineZoomLevel = this.zoomLevel;

    return false;
  }

  public toggle() {
    let currentState = this.current;

    currentState.toggle();

    this.state.putValue(currentState);
  }

  public get isVisible() {
    return this.current.isVisible;
  }

  public get zoomLevel() {
    return this.current.zoomLevel;
  }

  public updateZoom(delta: number) {
    let currentState = this.current;
    let idx = zoomLevelOrder.indexOf(this.current.zoomLevel);
    idx += delta;

    if (idx >= 0 && idx < zoomLevelOrder.length) {
      currentState.zoomLevel = zoomLevelOrder[idx];
      this.state.putValue(currentState);
    }
  }

  private get current():WorkPackageTableTimelineState {
    return this.state.value as WorkPackageTableTimelineState;
  }

}

opServicesModule.service('wpTableTimeline', WorkPackageTableTimelineService);
