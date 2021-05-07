import { TimelineZoomLevel } from 'core-app/modules/hal/resources/query-resource';
import * as moment from 'moment';

export type ExportTimelineConfig = {
  lineHeight: number,
  workHeight: number,
  fitDateInterval: boolean,
  fitDateIntervalMarginFactor: number,
  startDate: moment.Moment,
  endDate: moment.Moment,
  zoomLevel: TimelineZoomLevel,
  pixelPerDay: number,
  fontSize: number,
  nameColumnSize: number,
  boldLineColor: string,
  normalLineColor: string,
  smallLineColor: string,
  todayLineColor: string,
  relationLineColor: string,
  groupBackgroundColor: string,

  // Header configuration
  headerLine1Height: number,
  headerLine1FontStyle: string,
  headerLine1FontSize: number,
  headerLine2Height: number,
  headerLine2FontStyle: string,
  headerLine2FontSize: number,
  headerLine3Height: number,
  headerLine3FontStyle: string,
  headerLine3FontSize: number,
};
