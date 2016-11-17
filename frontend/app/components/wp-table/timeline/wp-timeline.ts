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

import WorkPackage = op.WorkPackage;
import Observable = Rx.Observable;
import Moment = moment.Moment;

export const timelineElementCssClass = "timeline-element";

// export type GlobalElementsRegistry = {[type: string]: (renderInfo: RenderInfo, elem: HTMLDivElement) => any};

/**
 *
 */
export class TimelineViewParametersSettings {

  showDurationInPx = true;

  pixelPerDay = 10;

  scrollOffsetInDays = 0;

}

/**
 *
 */
export class TimelineViewParameters {

  readonly now: Moment = moment({hour: 0, minute: 0, seconds: 0});

  dateDisplayStart: Moment = moment({hour: 0, minute: 0, seconds: 0});

  dateDisplayEnd: Moment = this.dateDisplayStart.clone().add(1, "day");

  settings: TimelineViewParametersSettings = new TimelineViewParametersSettings();

  get maxWidthInPx() {
    return this.dateDisplayEnd.diff(this.dateDisplayStart, "days") * this.settings.pixelPerDay;
  }

  get scrollOffsetInPx() {
    return this.settings.scrollOffsetInDays * this.settings.pixelPerDay;
  }

}

/**
 *
 */
export interface RenderInfo {
  viewParams: TimelineViewParameters;
  workPackage: WorkPackage;
  // globalElements: GlobalElementsRegistry;
}

/**
 *
 * @param viewParams
 * @param days
 * @returns {string}
 */
export function calculatePositionValueForDayCount(viewParams: TimelineViewParameters, days: number): string {
  const daysInPx = days * viewParams.settings.pixelPerDay;
  if (viewParams.settings.showDurationInPx) {
    return daysInPx + "px";
  } else {
    return (daysInPx / viewParams.maxWidthInPx * 100) + "%";
  }
}


