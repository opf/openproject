import {TimelineZoomLevel} from 'core-app/modules/hal/resources/query-resource';
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
import * as moment from 'moment';
import {InputState, MultiInputState} from 'reactivestates';
import {WorkPackageChangeset} from "core-components/wp-edit/work-package-changeset";
import {RenderedWorkPackage} from "core-app/modules/work_packages/render-info/rendered-work-package.type";
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import Moment = moment.Moment;

export const timelineElementCssClass = 'timeline-element';
export const timelineBackgroundElementClass = 'timeline-element--bg';
export const timelineGridElementCssClass = 'wp-timeline--grid-element';
export const timelineMarkerSelectionStartClass = 'selection-start';
export const timelineHeaderCSSClass = 'wp-timeline--header-element';
export const timelineHeaderSelector = 'wp-timeline-header';

/**
 *
 */
export class TimelineViewParametersSettings {

  zoomLevel:TimelineZoomLevel = 'days';

}

// Can't properly map the enum to a string aray
export const zoomLevelOrder:TimelineZoomLevel[] = [
  'days', 'weeks', 'months', 'quarters', 'years'
];

export function getPixelPerDayForZoomLevel(zoomLevel:TimelineZoomLevel) {
  switch (zoomLevel) {
    case 'days':
      return 30;
    case 'weeks':
      return 15;
    case 'months':
      return 6;
    case 'quarters':
      return 2;
    case 'years':
      return 0.5;
  }
  throw new Error('invalid zoom level: ' + zoomLevel);
}

/**
 * Number of pixels to display before the earliest workpackage in view
 */
export const requiredPixelMarginLeft = 120;

/**
 *
 */
export class TimelineViewParameters {

  readonly now:Moment = moment({hour: 0, minute: 0, seconds: 0});

  dateDisplayStart:Moment = moment({hour: 0, minute: 0, seconds: 0});

  dateDisplayEnd:Moment = this.dateDisplayStart.clone().add(1, 'day');

  settings:TimelineViewParametersSettings = new TimelineViewParametersSettings();

  activeSelectionMode:null | ((wp:WorkPackageResource) => any) = null;

  selectionModeStart:null | string = null;

  /**
   * The visible viewport (at the time the view parameters were calculated last!!!)
   */
  visibleViewportAtCalculationTime:[Moment, Moment];

  get pixelPerDay():number {
    return getPixelPerDayForZoomLevel(this.settings.zoomLevel);
  }

  get maxWidthInPx() {
    return this.maxSteps * this.pixelPerDay;
  }

  get maxSteps():number {
    return this.dateDisplayEnd.diff(this.dateDisplayStart, 'days');
  }

  get dayCountForMarginLeft():number {
    return Math.ceil(requiredPixelMarginLeft / this.pixelPerDay);
  }

}

/**
 *
 */
export interface RenderInfo {
  viewParams:TimelineViewParameters;
  workPackage:WorkPackageResource;
  change:WorkPackageChangeset;
}

/**
 *
 */
export function calculatePositionValueForDayCountingPx(viewParams:TimelineViewParameters, days:number):number {
  const daysInPx = days * viewParams.pixelPerDay;
  return daysInPx;
}

/**
 *
 */
export function calculatePositionValueForDayCount(viewParams:TimelineViewParameters, days:number):string {
  const value = calculatePositionValueForDayCountingPx(viewParams, days);
  return value + 'px';
}

export function getTimeSlicesForHeader(vp:TimelineViewParameters,
                                       unit:moment.unitOfTime.DurationConstructor,
                                       startView:Moment,
                                       endView:Moment) {

  const inViewport:[Moment, Moment][] = [];
  const rest:[Moment, Moment][] = [];

  const time = startView.clone().startOf(unit);
  const end = endView.clone().endOf(unit);

  while (time.isBefore(end)) {
    const sliceStart = moment.max(time, startView).clone();
    const sliceEnd = moment.min(time.clone().endOf(unit), endView).clone();
    time.add(1, unit);

    const viewport = vp.visibleViewportAtCalculationTime;
    if ((sliceStart.isSameOrAfter(viewport[0]) && sliceStart.isSameOrBefore(viewport[1]))
      || (sliceEnd.isSameOrAfter(viewport[0]) && sliceEnd.isSameOrBefore(viewport[1]))) {

      inViewport.push([sliceStart, sliceEnd]);
    } else {
      rest.push([sliceStart, sliceEnd]);
    }
  }

  const firstRest:[Moment, Moment] = rest.splice(0, 1)[0];
  const lastRest:[Moment, Moment] = rest.pop()!;
  const inViewportAndBoundaries = _.concat(
    [firstRest].filter(e => !_.isNil(e)),
    inViewport,
    [lastRest].filter(e => !_.isNil(e))
  );

  return {
    inViewportAndBoundaries,
    rest
  };

}

export function calculateDaySpan(visibleWorkPackages:RenderedWorkPackage[],
                                 loadedWorkPackages:MultiInputState<WorkPackageResource>,
                                 viewParameters:TimelineViewParameters):number {
  let earliest:Moment = moment();
  let latest:Moment = moment();

  visibleWorkPackages.forEach((renderedRow) => {
    const wpId = renderedRow.workPackageId;

    if (!wpId) {
      return;
    }
    const workPackageState:InputState<WorkPackageResource> = loadedWorkPackages.get(wpId);
    const workPackage:WorkPackageResource|undefined = workPackageState.value;

    if (!workPackage) {
      return;
    }

    const start = workPackage.startDate ? workPackage.startDate : workPackage.date;
    if (start && moment(start).isBefore(earliest)) {
      earliest = moment(start);
    }

    const due = workPackage.dueDate ? workPackage.dueDate : workPackage.date;
    if (due && moment(due).isAfter(latest)) {
      latest = moment(due);
    }
  });

  const daysSpan = latest.diff(earliest, 'days') + 1;
  return daysSpan;
}
