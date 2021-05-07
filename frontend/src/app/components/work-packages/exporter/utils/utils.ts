import { RenderInfo } from 'core-app/components/wp-table/timeline/wp-timeline';
import * as moment from 'moment';
import { ExportTimelineConfig } from '../ExportTimelineConfig';

export function calculatePositionValueForDayCountingPx(config:ExportTimelineConfig, days:number):number {
  return config.pixelPerDay * days;
}

export function computeXAndWidth(config:ExportTimelineConfig, start:moment.Moment, due:moment.Moment):{x:number, w:number} {
  const minWidth = _.max([config.pixelPerDay, 2]) || 2;
  if (_.isNaN(start.valueOf())) {
    const end = due.diff(config.startDate, 'days') * config.pixelPerDay;
    const w = minWidth;
    return {
      x: end,
      w,
    };
  } else if (_.isNaN(due.valueOf())) {
    const x = start.diff(config.startDate, 'days') * config.pixelPerDay;
    const w = minWidth;
    return {
      x,
      w,
    };
  }

  // offset left
  const offsetStart = start.diff(config.startDate, 'days');
  const x = config.pixelPerDay * offsetStart;

  // duration
  const duration = due.diff(start, 'days') + 1;
  let w = config.pixelPerDay * duration;

  // ensure minimum width
  if (!_.isNaN(start.valueOf()) || !_.isNaN(due.valueOf())) {
    const minWidth = _.max([config.pixelPerDay, 2]);
    if (minWidth) {
      w = Math.max(w, minWidth);
    }
  }

  return {
    x,
    w,
  };
}

export function getHeaderHeight(config:ExportTimelineConfig) {
  return config.headerLine1Height + config.headerLine2Height + config.headerLine3Height;
}
export function getHeaderWidth(config:ExportTimelineConfig):number {
  const days_count = config.endDate.diff(config.startDate, 'days');
  return calculatePositionValueForDayCountingPx(config, days_count);
}

export function getRowY(config:ExportTimelineConfig, row:number):number {
  return getHeaderHeight(config) + row * config.lineHeight;
}

export function isMilestone(renderInfo:RenderInfo):boolean {
  return !!renderInfo.change.projectedResource.date;
}

export function convertColorToInt(color:string):number[] {
  const ints = [0, 0, 0];
  if (color.charAt(0) === '#') {
    color = color.replace('#', '');
  }

  const match = /^(\w{2})(\w{2})(\w{2})$/.exec(color);

  if (match) {
    ints[0] = parseInt(match[1], 16);
    ints[1] = parseInt(match[2], 16);
    ints[2] = parseInt(match[3], 16);
  }

  return ints;
}
