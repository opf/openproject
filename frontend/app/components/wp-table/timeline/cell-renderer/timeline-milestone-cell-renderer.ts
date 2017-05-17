import {WorkPackageResourceInterface} from "../../../api/api-v3/hal-resources/work-package-resource.service";
import {TimelineCellRenderer} from "./timeline-cell-renderer";
import {
  RenderInfo,
  calculatePositionValueForDayCount,
  timelineElementCssClass,
  calculatePositionValueForDayCountingPx, timelineMarkerSelectionStartClass
} from "../wp-timeline";
import * as moment from "moment";
import { $injectNow } from "../../../angular/angular-injector-bridge.functions";
import Moment = moment.Moment;

interface CellMilestoneMovement {
  // Target value to move milestone to
  date?: moment.Moment;
}

export class TimelineMilestoneCellRenderer extends TimelineCellRenderer {
  public get type(): string {
    return 'milestone';
  }

  public isEmpty(wp: WorkPackageResourceInterface) {
    const date = moment(wp.date as any);
    const noDateValue = _.isNaN(date.valueOf());
    return noDateValue;
  }

  public displayPlaceholderUnderCursor(ev: MouseEvent, renderInfo: RenderInfo): HTMLElement {
    const days = Math.floor(ev.offsetX / renderInfo.viewParams.pixelPerDay);

    const placeholder = document.createElement("div");
    placeholder.className = "timeline-element milestone";
    placeholder.style.pointerEvents = "none";
    placeholder.style.height = "1em";
    placeholder.style.width = "1em";
    placeholder.style.left = (days * renderInfo.viewParams.pixelPerDay) + "px";

    const diamond = document.createElement("div");
    diamond.className = "diamond";
    diamond.style.backgroundColor = "#DDDDDD";
    diamond.style.left = "0.5em";
    diamond.style.height = "1em";
    diamond.style.width = "1em";
    placeholder.appendChild(diamond);

    return placeholder;
  }

  /**
   * Assign changed dates to the work package.
   * For generic work packages, assigns start and due date.
   *
   */
  public assignDateValues(wp: WorkPackageResourceInterface, dates: CellMilestoneMovement) {
    this.assignDate(wp, 'date', dates.date!);

    this.updateMilestoneMovedLabel(dates.date!);
  }

  /**
   * Restore the original date, if any was set.
   */
  public onCancel(wp: WorkPackageResourceInterface) {
    wp.restoreFromPristine('date');
  }

  /**
   * Handle movement by <delta> days of milestone.
   */
  public onDaysMoved(wp: WorkPackageResourceInterface,
                     dayUnderCursor: Moment,
                     delta: number,
                     direction: "left" | "right" | "both" | "create" | "dragright") {

    const initialDate = wp.$pristine['date'];
    let dates: CellMilestoneMovement = {};

    if (initialDate) {
      dates.date = moment(initialDate).add(delta, "days");
    }

    return dates;
  }

  public onMouseDown(ev: MouseEvent,
                     dateForCreate: string|null,
                     renderInfo: RenderInfo,
                     elem: HTMLElement): "left" | "right" | "both" | "create" | "dragright" {

    // check for active selection mode
    if (renderInfo.viewParams.activeSelectionMode) {
      renderInfo.viewParams.activeSelectionMode(renderInfo.workPackage);
      ev.preventDefault();
      return "both"; // irrelevant
    }

    let direction: "left" | "right" | "both" | "create" | "dragright" = "both";
    renderInfo.workPackage.storePristine('date');
    this.forceCursor('ew-resize');

    if (dateForCreate) {
      renderInfo.workPackage.date = dateForCreate;
      direction = "create";
      return direction;
    }

    // create date label
    const dateInfo = document.createElement("div");
    dateInfo.className = "rightDateDisplay";
    this.dateDisplaysOnMouseMove.right = dateInfo;
    elem.appendChild(dateInfo);

    this.updateMilestoneMovedLabel(moment(renderInfo.workPackage.date));

    return direction;
  }

  public update(timelineCell: HTMLElement, element: HTMLDivElement, renderInfo: RenderInfo): boolean {
    const wp = renderInfo.workPackage;
    const viewParams = renderInfo.viewParams;
    const date = moment(wp.date as any);

    // abort if no start or due date
    if (!wp.date) {
      return false;
    }

    const diamond = jQuery(".diamond", element)[0];

    element.style.width = '1em';
    element.style.height = '1em';
    diamond.style.width = '1em';
    diamond.style.height = '1em';
    diamond.style.backgroundColor = this.typeColor(wp);

    // offset left
    const offsetStart = date.diff(viewParams.dateDisplayStart, "days");
    element.style.left = 'calc(0.5em + ' + calculatePositionValueForDayCount(viewParams, offsetStart) + ')';

    this.checkForActiveSelectionMode(renderInfo, diamond);

    return true;
  }

  getLeftmostPosition(renderInfo: RenderInfo): number {
    const wp = renderInfo.workPackage;
    let start = moment(wp.date as any);
    const offsetStart = start.diff(renderInfo.viewParams.dateDisplayStart, "days");
    return calculatePositionValueForDayCountingPx(renderInfo.viewParams, offsetStart) + 20;
  }

  getRightmostPosition(renderInfo: RenderInfo): number {
    return this.getLeftmostPosition(renderInfo);
  }

  /**
   * Render a milestone element, a single day event with no resize, but
   * move functionality.
   */
  public render(renderInfo: RenderInfo): HTMLDivElement {
    const element = document.createElement("div");
    element.className = timelineElementCssClass + " " + this.type;

    const diamond = document.createElement("div");
    diamond.className = "diamond";
    element.appendChild(diamond);

    return element;
  }

  private updateMilestoneMovedLabel(date: Moment) {
    if (!this.TimezoneService) {
      this.TimezoneService = $injectNow('TimezoneService');
    }
    this.dateDisplaysOnMouseMove.right!.innerText = this.TimezoneService.formattedDate(date);
  }

}
