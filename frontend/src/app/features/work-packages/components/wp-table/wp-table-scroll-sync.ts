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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { runCleanup } from 'core-app/shared/helpers/angular/owned-ui-cleanup';

export const selectorTableSide = '.work-packages-tabletimeline--table-side';
export const selectorTimelineSide = '.work-packages-tabletimeline--timeline-side';
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

function syncWheelEvent(
  ev:WheelEvent, elementTable:HTMLElement, elementTimeline:HTMLElement, schedule:(callback:() => void) => void,
) {
  const scrollTarget = ev.target as HTMLElement;
  let [deltaX, deltaY] = getXandYScrollDeltas(ev);
  if (deltaY === 0) {
    return;
  }

  deltaX = getPlattformAgnosticScrollAmount(deltaX); // apply only in target div
  deltaY = getPlattformAgnosticScrollAmount(deltaY); // apply in both divs

  schedule(() => {
    elementTable.scrollTop = elementTable.scrollTop + deltaY;
    elementTimeline.scrollTop = elementTable.scrollTop + deltaY;

    scrollTarget.scrollLeft += deltaX;
  });
}

export interface ScrollSync {
  update(visible:boolean):void;
  destroy():void;
}

export function createScrollSync(element:HTMLElement):ScrollSync {
  const elTable = element.querySelector<HTMLElement>(selectorTableSide)!;
  const elTimeline = element.querySelector<HTMLElement>(selectorTimelineSide)!;
  const registrations:[HTMLElement, 'wheel'|'scroll', EventListener][] = [];
  let enabled = false;
  let destroyed = false;
  const frames = new Set<number>();
  const disable = () => {
    enabled = false;
    registrations.forEach(([node, type, callback]) => runCleanup(() => node.removeEventListener(type, callback)));
    registrations.length = 0;
    frames.forEach((id) => runCleanup(() => cancelAnimationFrame(id)));
    frames.clear();
  };
  const listen = (node:HTMLElement, type:'wheel'|'scroll', callback:EventListener) => {
    const ownedCallback:EventListener = (event) => {
      if (enabled && !destroyed) callback(event);
    };
    node.addEventListener(type, ownedCallback);
    registrations.push([node, type, ownedCallback]);
  };
  const schedule = (callback:() => void) => {
    const id = requestAnimationFrame(() => {
      frames.delete(id);
      if (enabled && !destroyed) callback();
    });
    frames.add(id);
  };

  return {
    update(timelineVisible:boolean) {
      if (!timelineVisible) {
        disable();
        return;
      }
      if (enabled || destroyed) return;
      enabled = true;
      let syncedLeft = false;
      let syncedRight = false;

      listen(elTable, 'wheel', (ev) => {
        syncWheelEvent(ev as WheelEvent, elTable, elTimeline, schedule);
      });
      listen(elTable, 'scroll', (ev) => {
        if (syncedRight) {
          syncedRight = false;
        } else {
          syncedLeft = true;
          elTimeline.scrollTop = (ev.target as HTMLElement).scrollTop;
        }
      });

      listen(elTimeline, 'wheel', (ev) => {
        syncWheelEvent(ev as WheelEvent, elTable, elTimeline, schedule);
      });
      listen(elTimeline, 'scroll', (ev) => {
        if (syncedLeft) {
          syncedLeft = false;
        } else {
          syncedRight = true;
          elTable.scrollTop = (ev.target as HTMLElement).scrollTop;
        }
      });
    },
    destroy() {
      destroyed = true;
      disable();
    },
  };
}
