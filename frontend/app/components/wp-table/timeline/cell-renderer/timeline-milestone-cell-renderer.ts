import {TimelineCellRenderer} from './timeline-cell-renderer';
import {RenderInfo, calculatePositionValueForDayCount, timelineElementCssClass} from './../wp-timeline';

export class TimelineMilestoneCellRenderer extends TimelineCellRenderer {
  public get type():string {
    return 'milestone';
  }

  /**
   * Assign changed dates to the work package.
   * For generic work packages, assigns start and due date.
   *
   */
  public assignDateValues(wp: op.WorkPackage, dates:{[name:string]: moment.Moment}) {
    this.assignDate(wp, 'date', dates['date']);
  }

  /**
   * Restore the original date, if any was set.
   */
  public onCancel(wp: op.WorkPackage, dates:{[name:string]: moment.Moment}) {
    this.assignDate(wp, 'date', dates['initialDate']);
  }

  /**
   * Handle movement by <delta> days of milestone.
   */
  public onDaysMoved(dates:{[name:string]: moment.Moment}, delta:number) {
    const initialDate = dates['initialDate'];

    if (initialDate) {
      dates['date'] = moment(initialDate).add(delta, "days");
    }

    return dates;
  }

  public onMouseDown(ev: MouseEvent, renderInfo:RenderInfo) {
    let dates:{[name:string]: moment.Moment} = {};

    this.forceCursor('ew-resize');
    dates['initialDate'] = moment(renderInfo.workPackage.date);

    return dates;
  }

  public update(element:HTMLDivElement, wp: op.WorkPackage, renderInfo:RenderInfo) {
    // abort if no start or due date
    if (!wp.date) {
      return;
    }

    element.style.marginLeft = renderInfo.viewParams.scrollOffsetInPx + "px";
    element.style.width = '1em';

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
    el.style.height = "1em";
    el.style.backgroundColor = "red";
    el.style.borderRadius = "2px";
    el.style.zIndex = "50";
    el.style.cursor = "ew-resize";
    el.style.transform = 'rotate(45deg)';
    el.style.transformOrigin = '75% 100%';

    return el;
  }
}