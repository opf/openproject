import {WorkPackageResourceInterface} from './../../../api/api-v3/hal-resources/work-package-resource.service';
import {TimelineCellRenderer} from './timeline-cell-renderer';
import {RenderInfo, calculatePositionValueForDayCount, timelineElementCssClass} from './../wp-timeline';

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
  }

  /**
   * Restore the original date, if any was set.
   */
  public onCancel(wp: WorkPackageResourceInterface, dates:CellMilestoneMovement) {
    wp.restoreFromPristine('date');
  }

  /**
   * Handle movement by <delta> days of milestone.
   */
  public onDaysMoved(wp:WorkPackageResourceInterface, delta:number) {
    const initialDate = wp.$pristine['date'];
    let dates:CellMilestoneMovement = {};

    if (initialDate) {
      dates.date = moment(initialDate).add(delta, "days");
    }

    return dates;
  }

  public onMouseDown(ev: MouseEvent, renderInfo:RenderInfo) {
    let dates:CellMilestoneMovement = {};

    this.forceCursor('ew-resize');
    renderInfo.workPackage.storePristine('date');

    return dates;
  }

  public willRender(renderInfo):boolean {
    const wp = renderInfo.workPackage;
    return !!wp.date;
  }

  public update(element:HTMLDivElement, wp: WorkPackageResourceInterface, renderInfo:RenderInfo) {
    // abort if no start or due date
    if (!wp.date) {
      return;
    }

    element.style.marginLeft = renderInfo.viewParams.scrollOffsetInPx + "px";
    element.style.width = '1em';
    element.style.height = '1em';

    const viewParams = renderInfo.viewParams;
    const date = moment(wp.date as any);

    // offset left
    const offsetStart = date.diff(viewParams.dateDisplayStart, "days");
    element.style.left = calculatePositionValueForDayCount(viewParams, offsetStart);
  }

  /**
   * Render a milestone element, a single day event with no resize, but
   * move functionality.
   */
  public render(renderInfo: RenderInfo):HTMLDivElement {
    const el = document.createElement("div");

    el.className = timelineElementCssClass + " " + this.type;
    el.style.position = "relative";
    el.style.backgroundColor = this.typeColor(renderInfo.workPackage as any);
    el.style.borderRadius = "2px";
    el.style.zIndex = "50";
    el.style.cursor = "ew-resize";
    el.style.transform = 'rotate(45deg)';
    el.style.transformOrigin = '75% 100%';

    return el;
  }
}