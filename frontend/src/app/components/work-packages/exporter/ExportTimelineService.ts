import {jsPDF} from 'jspdf';

import {Injector} from '@angular/core';
import {States} from '../../states.service';

import {HalResourceEditingService} from 'core-app/modules/fields/edit/services/hal-resource-editing.service';
import {RenderedWorkPackage} from 'core-app/modules/work_packages/render-info/rendered-work-package.type';
import {WorkPackageChangeset} from 'core-components/wp-edit/work-package-changeset';
import {InjectField} from 'core-app/helpers/angular/inject-field.decorator';
import {WorkPackageTimelineTableController} from 'core-app/components/wp-table/timeline/container/wp-timeline-container.directive';
import { WorkPackageTimelineCell } from 'core-app/components/wp-table/timeline/cells/wp-timeline-cell';
import { getPixelPerDayForZoomLevel, RenderInfo } from 'core-app/components/wp-table/timeline/wp-timeline';
import * as moment from 'moment';
import {renderHeader} from './ExportTimelineHeaderRenderer';
import { WorkPackageRelationsService } from 'core-app/components/wp-relations/wp-relations.service';
import {drawRelations} from './ExportTimelineRelationsRenderer';
import { IsolatedQuerySpace } from 'core-app/modules/work_packages/query-space/isolated-query-space';
import { GroupObject } from 'core-app/modules/hal/resources/wp-collection-resource';
import { ExportTimelineConfig } from './ExportTimelineConfig';
import { computeXAndWidth, getHeaderHeight, getHeaderWidth, getRowY, isMilestone } from './utils/utils';
import { HookService } from 'core-app/modules/plugins/hook-service';

export class ExportTimelineService {

  @InjectField() public states:States;
  @InjectField() public halEditing:HalResourceEditingService;
  @InjectField() private readonly querySpace:IsolatedQuerySpace;
  @InjectField() private hook:HookService;

  public cells:{ [classIdentifier:string]:WorkPackageTimelineCell } = {};

  public config: ExportTimelineConfig = {
    lineHeight: 20,
    workHeight: 10,
    fitDateInterval: true,
    fitDateIntervalMarginFactor: 0.1,
    startDate: moment({hour: 0, minute: 0, seconds: 0}),
    endDate: moment({hour: 0, minute: 0, seconds: 0}).add(1, 'day'),
    zoomLevel: 'days',
    pixelPerDay: 1,
    fontSize: 12,
    nameColumnSize: 200,
    boldLineColor: '#333333',
    normalLineColor: '#333333',
    smallLineColor: '#dddddd',
    todayLineColor: '#e74c3c',
    relationLineColor: '#3498db',
    groupBackgroundColor: '#f8f8f8',

    headerLine1Height: 20,
    headerLine1FontStyle: 'bold',
    headerLine1FontSize: 10,
    headerLine2Height: 10,
    headerLine2FontStyle: 'normal',
    headerLine2FontSize: 10,
    headerLine3Height: 25,
    headerLine3FontStyle: 'normal',
    headerLine3FontSize: 10,
  };

  constructor(public injector: Injector,
              readonly wpTimeline:WorkPackageTimelineTableController,
              readonly wpRelations:WorkPackageRelationsService) {

    this.exportPdf = this.exportPdf.bind(this);
    this.hook.register('export-gantt', this.exportPdf);
  }

  public exportPdf(config: Partial<ExportTimelineConfig>, cb: (doc:jsPDF) => void) {
    this.config = {...this.config, ...config};
    if (this.config.fitDateInterval) {
      this.fitStartAndEndDates();
    } else {
      this.config.startDate = this.wpTimeline.viewParameters.dateDisplayStart;
      this.config.endDate = this.wpTimeline.viewParameters.dateDisplayEnd;
    }
    this.config.pixelPerDay = getPixelPerDayForZoomLevel(this.config.zoomLevel);

    const width = getHeaderWidth(this.config) + this.config.nameColumnSize;
    const height = getHeaderHeight(this.config) + (this.querySpace.tableRendered.value || []).length * this.config.lineHeight;

    let doc = new jsPDF({
      orientation: 'l',
      unit: 'px',
      format: [width, height],
    });

    doc.setFontSize(this.config.fontSize);

    renderHeader(doc, this.config);
    drawRelations(doc, this.wpRelations, this.wpTimeline, this.config);
    doc = this.buildCells(doc);

    cb(doc);
  }

  private fitStartAndEndDates() {
    let startDate = +Infinity;
    let endDate = -Infinity;
    _.each(this.querySpace.tableRendered.value, (workPackage:RenderedWorkPackage) => {
      const wpId = workPackage.workPackageId;

      if (!wpId) {
        return;
      }

      const state = this.states.workPackages.get(wpId);
      if (state.isPristine()) {
        return;
      }

      const renderInfo = this.renderInfoFor(wpId);
      let wpStartDate = startDate;
      let wpEndDate = endDate;
      if (isMilestone(renderInfo)) {
        wpStartDate = moment(renderInfo.change.projectedResource.date).valueOf();
        wpEndDate = wpStartDate;
      } else {
        wpStartDate = moment(renderInfo.change.projectedResource.startDate).valueOf();
        wpEndDate = moment(renderInfo.change.projectedResource.dueDate).valueOf();
      }

      if (_.isNaN(wpStartDate) && _.isNaN(wpEndDate)) {
        return;
      }

      if (wpStartDate < startDate) {
        startDate = wpStartDate;
      }
      if (wpEndDate > endDate) {
        endDate = wpEndDate;
      }
    });

    const margin = this.config.fitDateIntervalMarginFactor * (endDate - startDate);

    this.config.startDate = moment(startDate - margin);
    this.config.endDate = moment(endDate + margin);
  }

  private buildCells(doc: jsPDF): jsPDF {
    const currentlyActive:string[] = Object.keys(this.cells);
    const newCells:string[] = [];
    let row = 0;
    const groups = mapGroupsByIdentifier(this.querySpace.groups.value || []);

    _.each(this.querySpace.tableRendered.value, (renderedRow:RenderedWorkPackage) => {
      const wpId = renderedRow.workPackageId;

      // Ignore extra rows not tied to a work package
      if (!wpId) {
        const group = groups[renderedRow.classIdentifier];
        if (group) {
          doc = buildGroupHeaderInfo(doc, this.config, row, group);
          row += 1;
        }
        return;
      }

      const state = this.states.workPackages.get(wpId);
      if (state.isPristine()) {
        return;
      }

      const renderInfo = this.renderInfoFor(wpId);
      buildTableInfo(doc, this.config, row, renderInfo);
      doc = isMilestone(renderInfo)
        ? this.buildMilestone(doc, row, renderInfo)
        : this.buildCell(doc, row, renderInfo);

      row += 1;
    });
    
    return doc;
  }

  private buildCell(doc: jsPDF, row: number, renderInfo: RenderInfo): jsPDF {    
    const change = renderInfo.change;
    const start = moment(change.projectedResource.startDate);
    const due = moment(change.projectedResource.dueDate);

    if (_.isNaN(start.valueOf()) && _.isNaN(due.valueOf())) {
      return doc;
    }

    let {x, w} = computeXAndWidth(this.config, start, due);
    const h = this.config.workHeight;
    let y = getRowY(this.config, row);
    y += (this.config.lineHeight - h) / 2;  // Vertically center workline
    const color = computeColor(renderInfo);

    x += this.config.nameColumnSize;

    doc.setFillColor(color);
    doc.rect(x, y, w, h, 'F');

    // Display the children's duration clamp
    const wp = renderInfo.workPackage;
    if (wp.derivedStartDate && wp.derivedDueDate) {
      const derivedStartDate = moment(wp.derivedStartDate);
      const derivedDueDate = moment(wp.derivedDueDate);

      ({x, w} = computeXAndWidth(this.config, derivedStartDate, derivedDueDate));
      x += this.config.nameColumnSize;
      y = getRowY(this.config, row + 1) - 2.5;
      doc.path([
        {op: 'm', c: [x, y + 5]},
        {op: 'l', c: [x, y]},
        {op: 'l', c: [x + w, y]},
        {op: 'l', c: [x + w, y + 5]},
      ]);
      doc.stroke();
    }

    return doc;
  }

  private buildMilestone(doc: jsPDF, row: number, renderInfo: RenderInfo): jsPDF {    
    const change = renderInfo.change;
    const date = moment(change.projectedResource.date);

    if (_.isNaN(date.valueOf())) {
      return doc;
    }

    let {x, w} = computeXAndWidth(this.config, date, date);
    const h = this.config.workHeight;
    const half_size = h / 2;
    let y = getRowY(this.config, row);
    y += (this.config.lineHeight - h) / 2;  // Vertically center milestone
    let color = computeColor(renderInfo);

    x += this.config.nameColumnSize;

    doc.setFillColor(color);
    doc.lines([
      [half_size, half_size],
      [-half_size, half_size],
      [-half_size, -half_size],
    ], x + w / 2, y, [1,1], 'F', true);

    return doc;
  }

  private renderInfoFor(wpId:string):RenderInfo {
    const wp = this.states.workPackages.get(wpId).value!;
    return {
      viewParams: this.wpTimeline.viewParameters,
      workPackage: wp,
      change: this.halEditing.changeFor(wp) as WorkPackageChangeset
    };
  }
}

const colors: Record<string, string> = {
  '1': '#1A67A3',
  '2': '#35C53F',
  '3': '#FF922B',
  '4': '#5C7CFA',
  '5': '#845EF7',
  '6': '#00B0F0',
  '7': '#F03E3E',
};

function computeColor(renderInfo:RenderInfo) {
  const wp = renderInfo.workPackage;
  const type = wp.type;
  const id = type.id || '';

  return colors[id] || '#FFFFFF';
}

function buildTableInfo(doc:jsPDF, config:ExportTimelineConfig, row:number, renderInfo:RenderInfo): jsPDF {
  const h = config.lineHeight;
  const start_y = getRowY(config, row);
  const width = config.nameColumnSize;
  doc.setDrawColor('#2c3e50');
  doc.line(0, start_y, width, start_y);
  doc.line(0, start_y + h, width, start_y + h);

  doc.setFontSize(config.fontSize);
  doc.text(renderInfo.change.projectedResource.name, 10, start_y + h / 2, {
    baseline: 'middle',
  });

  return doc;
}

function buildGroupHeaderInfo(doc:jsPDF, config:ExportTimelineConfig, row:number, group:GroupObject): jsPDF {
  const h = config.lineHeight;
  const start_y = getRowY(config, row);
  const width = config.nameColumnSize;
  doc.setFillColor(config.groupBackgroundColor);
  doc.rect(0, start_y, width - 1, h, 'F');
  doc.setDrawColor('#2c3e50');
  doc.line(0, start_y, width, start_y);
  doc.line(0, start_y + h, width, start_y + h);

  doc.setFontSize(config.fontSize);
  doc.text(`${group.value} (${group.count})`, 10, start_y + h / 2, {
    baseline: 'middle',
  });

  return doc;
}

function mapGroupsByIdentifier(groups: GroupObject[]): Record<string, GroupObject> {
  const map:Record<string, GroupObject> = {};

  for (let group of groups) {
    const id = 'group-'+ group.identifier;
    if (map[id]) {
      console.warn(`Group with identifier ${id} was already defined`);
    }
    map[id] = group;
  }

  return map;
}
