import {WorkPackageResourceInterface} from "../../../api/api-v3/hal-resources/work-package-resource.service";
import {TimelineCellRenderer} from "./timeline-cell-renderer";
import {RenderInfo, calculatePositionValueForDayCount, timelineElementCssClass} from "../wp-timeline";
import Moment = moment.Moment;

interface CellMilestoneMovement {
  // Target value to move milestone to
  date?: moment.Moment;
}

export class TimelineMilestoneCellRenderer extends TimelineCellRenderer {

  public get type():string {
    return 'milestone';
  }

  public get fallbackColor():string {
    return '#C0392B';
  }

  /**
   * Assign changed dates to the work package.
   * For generic work packages, assigns start and due date.
   *
   */
  public assignDateValues(wp: WorkPackageResourceInterface, dates:CellMilestoneMovement) {
    this.assignDate(wp, 'date', dates.date);

    this.updateMilestoneMovedLabel(dates.date);
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
  public onDaysMoved(wp:WorkPackageResourceInterface, delta:number, direction: "left" | "right" | "both") {
    const initialDate = wp.$pristine['date'];
    let dates:CellMilestoneMovement = {};

    if (initialDate) {
      dates.date = moment(initialDate).add(delta, "days");
    }

    return dates;
  }

  public onMouseDown(ev: MouseEvent, renderInfo: RenderInfo, elem: HTMLElement): "left" | "right" | "both" {
    this.forceCursor('ew-resize');
    renderInfo.workPackage.storePristine('date');

    // create date label
    const dateInfo = document.createElement("div");
    dateInfo.className = "rightDateDisplay";
    this.dateDisplaysOnMouseMove.right = dateInfo;
    elem.appendChild(dateInfo);

    this.updateMilestoneMovedLabel(moment(renderInfo.workPackage.date));

    return "both";
  }

  public update(element:HTMLDivElement, wp: WorkPackageResourceInterface, renderInfo:RenderInfo): boolean {
    // abort if no start or due date
    if (!wp.date) {
      return false;
    }

    const diamond = jQuery(".diamond", element)[0];

    element.style.marginLeft = renderInfo.viewParams.scrollOffsetInPx + "px";
    element.style.width = '1em';
    element.style.height = '1em';
    diamond.style.width = '1em';
    diamond.style.height = '1em';

    diamond.style.backgroundColor = this.typeColor(renderInfo.workPackage);

    const viewParams = renderInfo.viewParams;
    const date = moment(wp.date as any);

    // offset left
    const offsetStart = date.diff(viewParams.dateDisplayStart, "days");
    element.style.left = 'calc(0.5em + ' + calculatePositionValueForDayCount(viewParams, offsetStart) + ')';

    return true;
  }

  /**
   * Render a milestone element, a single day event with no resize, but
   * move functionality.
   */
  public render(renderInfo: RenderInfo):HTMLDivElement {
    const element = document.createElement("div");
    element.className = timelineElementCssClass + " " + this.type;

    const diamond = document.createElement("div");
    diamond.className = "diamond";
    element.appendChild(diamond);

    return element;
  }

  private updateMilestoneMovedLabel(date: Moment) {
    this.dateDisplaysOnMouseMove.right.innerText = date.format("L");
  }

}
