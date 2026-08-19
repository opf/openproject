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

import { target } from 'core-app/shared/helpers/event-helpers';

export const selectorTableSide = '.work-packages-tabletimeline--table-side';
export const selectorTimelineSide = '.work-packages-tabletimeline--timeline-side';
const scrollSyncEventNamespace = '.scroll-sync';
const scrollStep = 15;

function getXandYScrollDeltas(ev:WheelEvent):[number, number] {
  let x = ev.deltaX;
  let y = ev.deltaY;

  if (ev.shiftKey) {
    x = y;
    y = 0;
  }

  return [x, y];
}

function getPlattformAgnosticScrollAmount(originalValue:number) {
  if (originalValue === 0) {
    return originalValue;
  }

  let delta = scrollStep;

  // Browser-specific logic
  // TODO

  if (originalValue < 0) {
    delta *= -1;
  }
  return delta;
}

function syncWheelEvent(ev:WheelEvent, elementTable:HTMLElement, elementTimeline:HTMLElement) {
  const scrollTarget = ev.target as HTMLElement;
  let [deltaX, deltaY] = getXandYScrollDeltas(ev);
  if (deltaY === 0) {
    return;
  }

  deltaX = getPlattformAgnosticScrollAmount(deltaX); // apply only in target div
  deltaY = getPlattformAgnosticScrollAmount(deltaY); // apply in both divs

  window.requestAnimationFrame(() => {
    elementTable.scrollTop = elementTable.scrollTop + deltaY;
    elementTimeline.scrollTop = elementTable.scrollTop + deltaY;

    scrollTarget.scrollLeft += deltaX;
  });
}

/**
 * Activate or deactivate the scroll-sync between the table and timeline view.
 *
 * @param element true if the timeline is visible, false otherwise.
 */
export function createScrollSync(element:HTMLElement) {
  const elTable = element.querySelector<HTMLElement>(selectorTableSide)!;
  const elTimeline = element.querySelector<HTMLElement>(selectorTimelineSide)!;

  return (timelineVisible:boolean) => {
    // state vars
    let syncedLeft = false;
    let syncedRight = false;

    if (timelineVisible) {
      // setup event listener for table
      target(elTable).on(`wheel${scrollSyncEventNamespace}`, (ev:WheelEvent) => {
        syncWheelEvent(ev, elTable, elTimeline);
      });
      target(elTable).on(`scroll${scrollSyncEventNamespace}`, (ev:Event) => {
        syncedLeft = true;
        if (!syncedRight) {
          elTimeline.scrollTop = (ev.target as HTMLElement).scrollTop;
        }
        if (syncedLeft && syncedRight) {
          syncedLeft = false;
          syncedRight = false;
        }
      });

      // setup event listener for timeline
      target(elTimeline).on(`wheel${scrollSyncEventNamespace}`, (ev:WheelEvent) => {
        syncWheelEvent(ev, elTable, elTimeline);
      });
      target(elTimeline).on(`scroll${scrollSyncEventNamespace}`, (ev:Event) => {
        syncedRight = true;
        if (!syncedLeft) {
          elTable.scrollTop = (ev.target as HTMLElement).scrollTop;
        }
        if (syncedLeft && syncedRight) {
          syncedLeft = false;
          syncedRight = false;
        }
      });
    } else {
      target(elTable).off(scrollSyncEventNamespace);
    }
  };
}
