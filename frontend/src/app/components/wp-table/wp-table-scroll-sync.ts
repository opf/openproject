//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

export const selectorTableSide = ".work-packages-tabletimeline--table-side";
export const selectorTimelineSide = ".work-packages-tabletimeline--timeline-side";
const jQueryScrollSyncEventNamespace = ".scroll-sync";
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

function syncWheelEvent(jev:JQuery.TriggeredEvent, elementTable:JQuery, elementTimeline:JQuery) {
  const scrollTarget = jev.target;
  const ev:WheelEvent = jev.originalEvent as any;
  let [deltaX, deltaY] = getXandYScrollDeltas(ev);

  if (deltaY === 0) {
    return;
  }

  deltaX = getPlattformAgnosticScrollAmount(deltaX); // apply only in target div
  deltaY = getPlattformAgnosticScrollAmount(deltaY); // apply in both divs

  window.requestAnimationFrame(function () {
    elementTable[0].scrollTop = elementTable[0].scrollTop + deltaY;
    elementTimeline[0].scrollTop = elementTimeline[0].scrollTop + deltaY;

    scrollTarget.scrollLeft = scrollTarget.scrollLeft + deltaX;
  });
}

/**
 * Activate or deactivate the scroll-sync between the table and timeline view.
 *
 * @param $element true if the timeline is visible, false otherwise.
 */
export function createScrollSync($element:JQuery) {

  var elTable = jQuery($element).find(selectorTableSide);
  var elTimeline = jQuery($element).find(selectorTimelineSide);

  return (timelineVisible:boolean) => {

    // state vars
    var syncedLeft = false;
    var syncedRight = false;

    if (timelineVisible) {
      // setup event listener for table
      elTable.on("wheel" + jQueryScrollSyncEventNamespace, (jev:JQuery.TriggeredEvent) => {
        syncWheelEvent(jev, elTable, elTimeline);
      });
      elTable.on("scroll" + jQueryScrollSyncEventNamespace, (ev:JQuery.TriggeredEvent) => {
        syncedLeft = true;
        if (!syncedRight) {
          elTimeline[0].scrollTop = ev.target.scrollTop;
        }
        if (syncedLeft && syncedRight) {
          syncedLeft = false;
          syncedRight = false;
        }
      });

      // setup event listener for timeline
      elTimeline.on("wheel" + jQueryScrollSyncEventNamespace, (jev:JQuery.TriggeredEvent) => {
        syncWheelEvent(jev, elTable, elTimeline);
      });
      elTimeline.on("scroll" + jQueryScrollSyncEventNamespace, (ev:JQuery.TriggeredEvent) => {
        syncedRight = true;
        if (!syncedLeft) {
          elTable[0].scrollTop = ev.target.scrollTop;
        }
        if (syncedLeft && syncedRight) {
          syncedLeft = false;
          syncedRight = false;
        }
      });
    } else {
      elTable.off(jQueryScrollSyncEventNamespace);
    }
  };

}
